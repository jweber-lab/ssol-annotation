#!/usr/bin/env bash
# 01_trnascan.sh — Predict tRNA genes with tRNAscan-SE.
set -euo pipefail
source "$(dirname "$0")/../config.sh"

NCRNA_DIR="${OUTDIR}/ncrna"
mkdir -p "${NCRNA_DIR}"

echo "=== Running tRNAscan-SE (eukaryotic mode) ==="
tRNAscan-SE \
    -E \
    --thread "${THREADS}" \
    -o "${NCRNA_DIR}/trnascan.out" \
    -f "${NCRNA_DIR}/trnascan.ss" \
    -m "${NCRNA_DIR}/trnascan.stats" \
    --gff "${NCRNA_DIR}/trnascan.gff3" \
    "${GENOME}"

TRNA_COUNT=$(grep -cP '\ttRNA\t' "${NCRNA_DIR}/trnascan.gff3" || true)
echo "=== tRNAscan-SE complete: ${TRNA_COUNT} tRNAs predicted ==="
echo "Results: ${NCRNA_DIR}/trnascan.out"
echo "GFF3:    ${NCRNA_DIR}/trnascan.gff3"
echo "Stats:   ${NCRNA_DIR}/trnascan.stats"
