#!/usr/bin/env bash
# 01_transposonpsi.sh — Detect transposon homology with TransposonPSI.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

TE_DIR="${OUTDIR}/transposons"
WORK_DIR="${TMPDIR_BASE}/transposonpsi"
mkdir -p "${TE_DIR}" "${WORK_DIR}"

FILTERED_PROT="${OUTDIR}/maker/${GENOME_LABEL}_filtered.proteins.fasta"

if [[ ! -f "${FILTERED_PROT}" ]]; then
    echo "ERROR: Filtered proteins not found: ${FILTERED_PROT}"
    echo "Run 04-maker/ scripts first."
    exit 1
fi

cd "${WORK_DIR}"

# ── 1. Search predicted proteins ─────────────────────────────────────────────
echo "=== TransposonPSI: protein mode ==="
transposonPSI.pl "${FILTERED_PROT}" prot
mv "$(basename "${FILTERED_PROT}").TPSI.topHits"  "${TE_DIR}/proteins.TPSI.topHits"  2>/dev/null || true
mv "$(basename "${FILTERED_PROT}").TPSI.allHits"  "${TE_DIR}/proteins.TPSI.allHits"  2>/dev/null || true

PROT_HITS=$(wc -l < "${TE_DIR}/proteins.TPSI.topHits" 2>/dev/null || echo 0)
echo "Protein transposon hits: ${PROT_HITS}"

# ── 2. Search genome sequence ────────────────────────────────────────────────
echo "=== TransposonPSI: nucleotide mode ==="
transposonPSI.pl "${GENOME}" nuc
mv "$(basename "${GENOME}").TPSI.topHits"  "${TE_DIR}/genome.TPSI.topHits"  2>/dev/null || true
mv "$(basename "${GENOME}").TPSI.allHits"  "${TE_DIR}/genome.TPSI.allHits"  2>/dev/null || true

GENOME_HITS=$(wc -l < "${TE_DIR}/genome.TPSI.topHits" 2>/dev/null || echo 0)
echo "Genome transposon hits: ${GENOME_HITS}"

echo "=== TransposonPSI complete ==="
echo "Results in: ${TE_DIR}/"
