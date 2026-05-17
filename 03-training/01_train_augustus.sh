#!/usr/bin/env bash
# 01_train_augustus.sh — Train an AUGUSTUS species model for S. solidus.
#
# Workflow: align reference proteins -> select training genes -> train -> optimise.
# Requires: AUGUSTUS, BLAST+, exonerate (or scipio), bedtools, awk.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AWK_SPLIT="${SCRIPT_DIR}/split_protein_fasta_chunks.awk"

SPECIES="ssol"
TRAIN_DIR="${OUTDIR}/training/augustus"
MASKED_GENOME="${OUTDIR}/repeats/$(basename "${GENOME}").masked"
WORK_DIR="${TMPDIR_BASE}/augustus"
CHUNK_DIR="${WORK_DIR}/exonerate_chunks"

MAXSEQS="${EXONERATE_CHUNK_MAX_SEQS:-5000}"
MAXRES="${EXONERATE_CHUNK_MAX_RESIDUES:-3000000}"

mkdir -p "${TRAIN_DIR}" "${WORK_DIR}"

if [[ ! -f "${MASKED_GENOME}" ]]; then
    echo "ERROR: Masked genome not found: ${MASKED_GENOME}"
    echo "Run 01-repeats/ scripts first."
    exit 1
fi

if [[ ! -f "${AWK_SPLIT}" ]]; then
    echo "ERROR: Missing awk splitter: ${AWK_SPLIT}"
    exit 1
fi

# ── 1. Combine reference proteins into a single FASTA ────────────────────────
COMBINED_PROT="${TRAIN_DIR}/ref_proteins.faa"
cat "${REF_PROTEINS[@]}" > "${COMBINED_PROT}"
NPROT=$(grep -c '^>' "${COMBINED_PROT}" || true)
echo "Combined ${NPROT} reference proteins."

EXONERATE_GFF="${TRAIN_DIR}/exonerate_hits.gff"

run_exonerate() {
    local query_faa="$1"
    local out_gff="$2"
    exonerate \
        --model protein2genome \
        --query "${query_faa}" \
        --target "${MASKED_GENOME}" \
        --percent 50 \
        --showtargetgff yes \
        --showvulgar no \
        --showalignment no \
        --ryo "" \
        --bestn 1 \
        > "${out_gff}"
}

merge_exonerate_chunk_gffs() {
    local merged_out="$1"
    shift
    local -a gffs=("$@")
    local tmp="${merged_out}.merge_tmp"

    if (( ${#gffs[@]} == 0 )); then
        echo "ERROR: No chunk GFF files to merge."
        exit 1
    fi

    {
        echo "##gff-version 2"
        local f
        for f in "${gffs[@]}"; do
            [[ -s "${f}" ]] || continue
            grep -v '^##' "${f}" || true
        done
    } > "${tmp}"

    grep '^#' "${tmp}" > "${merged_out}.hdr" 2>/dev/null || touch "${merged_out}.hdr"
    grep -v '^#' "${tmp}" | LC_ALL=C sort -t $'\t' -k1,1 -k4,4n -k5,5n > "${merged_out}.feat"
    cat "${merged_out}.hdr" "${merged_out}.feat" > "${merged_out}"
    rm -f "${tmp}" "${merged_out}.hdr" "${merged_out}.feat"
}

# ── 2. Align proteins to the masked genome with exonerate ────────────────────
echo "=== Aligning reference proteins to masked genome with exonerate ==="

if [[ "${MAXSEQS}" -eq 0 && "${MAXRES}" -eq 0 ]]; then
    echo "Chunking disabled (EXONERATE_CHUNK_MAX_SEQS=0 and EXONERATE_CHUNK_MAX_RESIDUES=0); single exonerate run."
    run_exonerate "${COMBINED_PROT}" "${EXONERATE_GFF}"
else
    echo "Chunking: max ${MAXSEQS} sequences / max ${MAXRES} residues per chunk (0 = unlimited for that axis)."
    rm -rf "${CHUNK_DIR}"
    mkdir -p "${CHUNK_DIR}"

    awk -v max_seqs="${MAXSEQS}" -v max_res="${MAXRES}" \
        -v out_prefix="${CHUNK_DIR}/chunk_" \
        -f "${AWK_SPLIT}" \
        "${COMBINED_PROT}"

    mapfile -t CHUNK_FASTAS < <(find "${CHUNK_DIR}" -maxdepth 1 -name 'chunk_*.faa' | LC_ALL=C sort)
    if (( ${#CHUNK_FASTAS[@]} == 0 )); then
        echo "ERROR: No chunk FASTA files produced under ${CHUNK_DIR}"
        exit 1
    fi

    echo "Running exonerate on ${#CHUNK_FASTAS[@]} chunk(s)..."
    CHUNK_GFFS=()
    chunk_idx=0
    for chunk_faa in "${CHUNK_FASTAS[@]}"; do
        chunk_idx=$((chunk_idx + 1))
        base="$(basename "${chunk_faa}" .faa)"
        chunk_gff="${CHUNK_DIR}/${base}.gff"
        echo "--- Chunk ${chunk_idx}/${#CHUNK_FASTAS[@]}: ${chunk_faa} ---"
        run_exonerate "${chunk_faa}" "${chunk_gff}"
        CHUNK_GFFS+=("${chunk_gff}")
    done

    merge_exonerate_chunk_gffs "${EXONERATE_GFF}" "${CHUNK_GFFS[@]}"
    echo "Merged chunk GFFs -> ${EXONERATE_GFF}"
fi

# ── 3. Filter for high-quality, non-overlapping training genes ───────────────
TRAINING_GFF="${TRAIN_DIR}/training_genes.gff"
TRAINING_GB="${TRAIN_DIR}/training_genes.gb"

# Keep only complete gene models (start + stop codons) and remove overlaps.
grep -P '\tgene\t' "${EXONERATE_GFF}" \
    | sort -k1,1 -k4,4n \
    | bedtools merge -i - -d 0 -c 4 -o count \
    | awk '$4 == 1' \
    > "${TRAIN_DIR}/non_overlapping_regions.bed"

# Extract corresponding exonerate GFF entries (simplified; may need refinement).
bedtools intersect \
    -a "${EXONERATE_GFF}" \
    -b "${TRAIN_DIR}/non_overlapping_regions.bed" \
    -u \
    > "${TRAINING_GFF}"

GENE_COUNT=$(grep -c '\tgene\t' "${TRAINING_GFF}" || true)
echo "Training set: ${GENE_COUNT} non-overlapping gene models."

if (( GENE_COUNT < 200 )); then
    echo "WARNING: Fewer than 200 training genes. Model quality may be low."
    echo "Consider using the MAKER iterative approach (see README)."
fi

# Convert GFF + genome to GenBank format for AUGUSTUS.
gff2gbSmallDNA.pl "${TRAINING_GFF}" "${MASKED_GENOME}" 1000 "${TRAINING_GB}"

# ── 4. Create new AUGUSTUS species and train ──────────────────────────────────
echo "=== Creating AUGUSTUS species: ${SPECIES} ==="
new_species.pl --species="${SPECIES}" || true

echo "=== Initial training ==="
etraining --species="${SPECIES}" "${TRAINING_GB}"

cd "${WORK_DIR}"
echo "=== Optimising parameters (6 rounds) ==="
optimize_augustus.pl \
    --species="${SPECIES}" \
    --rounds=6 \
    --cpus="${THREADS}" \
    "${TRAINING_GB}"
cd "${REPO_ROOT}"

echo "=== Final training with optimised parameters ==="
etraining --species="${SPECIES}" "${TRAINING_GB}"

echo "=== AUGUSTUS training complete for species '${SPECIES}' ==="
