#!/usr/bin/env bash
# 01_repeatmodeler.sh — Build a de novo repeat library with RepeatModeler.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

REPEAT_DIR="${OUTDIR}/repeats"
mkdir -p "${REPEAT_DIR}"

DB_NAME="${REPEAT_DIR}/${GENOME_LABEL}"

echo "=== Building RepeatModeler database ==="
BuildDatabase -name "${DB_NAME}" "${GENOME}"

echo "=== Running RepeatModeler ==="
RepeatModeler \
    -database "${DB_NAME}" \
    -threads "${THREADS}" \
    -LTRStruct

echo "=== RepeatModeler complete ==="
echo "Repeat library: ${DB_NAME}-families.fa"
