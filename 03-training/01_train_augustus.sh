#!/usr/bin/env bash
# 01_train_augustus.sh — Train an AUGUSTUS species model for S. solidus.
#
# Workflow: align reference proteins -> select training genes -> train -> optimise.
# Requires: AUGUSTUS, BLAST+, exonerate (or scipio), bedtools.
set -euo pipefail
source "$(dirname "$0")/../config.sh"

SPECIES="ssol"
TRAIN_DIR="${OUTDIR}/training/augustus"
MASKED_GENOME="${OUTDIR}/repeats/$(basename "${GENOME}").masked"
mkdir -p "${TRAIN_DIR}"

if [[ ! -f "${MASKED_GENOME}" ]]; then
    echo "ERROR: Masked genome not found: ${MASKED_GENOME}"
    echo "Run 01-repeats/ scripts first."
    exit 1
fi

# ── 1. Combine reference proteins into a single FASTA ────────────────────────
COMBINED_PROT="${TRAIN_DIR}/ref_proteins.faa"
cat "${REF_PROTEINS[@]}" > "${COMBINED_PROT}"
echo "Combined $(grep -c '^>' "${COMBINED_PROT}") reference proteins."

# ── 2. Align proteins to the masked genome with exonerate ────────────────────
#    Produces GFF2 gene models; convert to GenBank for AUGUSTUS training.
EXONERATE_GFF="${TRAIN_DIR}/exonerate_hits.gff"
echo "=== Aligning reference proteins to masked genome with exonerate ==="
exonerate \
    --model protein2genome \
    --query "${COMBINED_PROT}" \
    --target "${MASKED_GENOME}" \
    --percent 50 \
    --showtargetgff yes \
    --showvulgar no \
    --showalignment no \
    --ryo "" \
    --bestn 1 \
    > "${EXONERATE_GFF}"

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
new_species.pl --species="${SPECIES}" || true   # ok if already exists

echo "=== Initial training ==="
etraining --species="${SPECIES}" "${TRAINING_GB}"

echo "=== Optimising parameters (6 rounds) ==="
optimize_augustus.pl \
    --species="${SPECIES}" \
    --rounds=6 \
    --cpus="${THREADS}" \
    "${TRAINING_GB}"

echo "=== Final training with optimised parameters ==="
etraining --species="${SPECIES}" "${TRAINING_GB}"

echo "=== AUGUSTUS training complete for species '${SPECIES}' ==="
