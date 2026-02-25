#!/usr/bin/env bash
# 03_bam2hints.sh — Extract intron hints from the STAR BAM for AUGUSTUS/MAKER.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

ALIGN_DIR="${OUTDIR}/rnaseq/star_align"
HINTS_DIR="${OUTDIR}/rnaseq"
BAM="${ALIGN_DIR}/Aligned.sortedByCoord.out.bam"
HINTS="${HINTS_DIR}/hints.gff"

if [[ ! -f "${BAM}" ]]; then
    echo "ERROR: BAM not found: ${BAM}"
    echo "Run 02_star_align.sh first."
    exit 1
fi

echo "=== Extracting intron hints with bam2hints ==="
bam2hints \
    --intronsonly \
    --in="${BAM}" \
    --out="${HINTS}"

HINT_COUNT=$(wc -l < "${HINTS}")
echo "=== bam2hints complete: ${HINT_COUNT} hints written to ${HINTS} ==="
