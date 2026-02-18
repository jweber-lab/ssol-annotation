#!/usr/bin/env bash
# 01_star_index.sh — Build a STAR genome index from the unmasked assembly.
set -euo pipefail
source "$(dirname "$0")/../config.sh"

INDEX_DIR="${OUTDIR}/rnaseq/star_index"
mkdir -p "${INDEX_DIR}"

# Compute genomeSAindexNbases from genome size (default 14 is for human-scale).
GENOME_SIZE=$(awk '/^[^>]/{n+=length}END{print n}' "${GENOME}")
SA_BASES=$(python3 -c "import math; print(min(14, int(math.log2(${GENOME_SIZE})/2 - 1)))")
echo "Genome size: ${GENOME_SIZE} bp -> genomeSAindexNbases: ${SA_BASES}"

echo "=== Building STAR index ==="
STAR \
    --runMode genomeGenerate \
    --runThreadN "${THREADS}" \
    --genomeDir "${INDEX_DIR}" \
    --genomeFastaFiles "${GENOME}" \
    --genomeSAindexNbases "${SA_BASES}"

echo "=== STAR index complete: ${INDEX_DIR} ==="
