#!/usr/bin/env bash
# 01_blast_uniprot.sh — Functional annotation via BLASTp against Swiss-Prot.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

FUNC_DIR="${OUTDIR}/functional"
mkdir -p "${FUNC_DIR}"

FILTERED_GFF="${OUTDIR}/maker/${GENOME_LABEL}_filtered.gff"
FILTERED_PROT="${OUTDIR}/maker/${GENOME_LABEL}_filtered.proteins.fasta"
BLAST_OUT="${FUNC_DIR}/blastp_sprot.outfmt6"
ANNOTATED_GFF="${FUNC_DIR}/${GENOME_LABEL}_annotated.gff"
ANNOTATED_PROT="${FUNC_DIR}/${GENOME_LABEL}_annotated.proteins.fasta"

if [[ ! -f "${FILTERED_PROT}" ]]; then
    echo "ERROR: Filtered proteins not found: ${FILTERED_PROT}"
    echo "Run 04-maker/ scripts first."
    exit 1
fi

# ── 1. Build Swiss-Prot BLAST database (if not already built) ────────────────
SPROT_DB="${FUNC_DIR}/sprot_db"
if [[ ! -f "${SPROT_DB}.pdb" ]] && [[ ! -f "${SPROT_DB}.psq" ]]; then
    echo "=== Building Swiss-Prot BLAST database ==="
    makeblastdb \
        -in "${UNIPROT_FASTA}" \
        -dbtype prot \
        -out "${SPROT_DB}" \
        -parse_seqids
fi

# ── 2. BLASTp search ────────────────────────────────────────────────────────
echo "=== Running BLASTp against Swiss-Prot ==="
blastp \
    -query "${FILTERED_PROT}" \
    -db "${SPROT_DB}" \
    -evalue 1e-5 \
    -max_target_seqs 5 \
    -outfmt 6 \
    -num_threads "${THREADS}" \
    -out "${BLAST_OUT}"

HIT_COUNT=$(cut -f1 "${BLAST_OUT}" | sort -u | wc -l)
echo "Proteins with Swiss-Prot hits: ${HIT_COUNT}"

# ── 3. Map descriptions to GFF3 and FASTA ───────────────────────────────────
echo "=== Adding functional descriptions to GFF3 ==="
cp "${FILTERED_GFF}" "${ANNOTATED_GFF}"
maker_functional_gff "${UNIPROT_FASTA}" "${BLAST_OUT}" "${ANNOTATED_GFF}"

echo "=== Adding functional descriptions to protein FASTA ==="
cp "${FILTERED_PROT}" "${ANNOTATED_PROT}"
maker_functional_fasta "${UNIPROT_FASTA}" "${BLAST_OUT}" "${ANNOTATED_PROT}"

echo "=== Functional annotation complete ==="
echo "Annotated GFF3: ${ANNOTATED_GFF}"
echo "Annotated proteins: ${ANNOTATED_PROT}"
echo "BLAST results: ${BLAST_OUT}"
