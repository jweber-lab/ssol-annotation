#!/usr/bin/env bash
# 01_repeatmodeler.sh — Build a de novo repeat library with RepeatModeler.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

REPEAT_DIR="${OUTDIR}/repeats"
mkdir -p "${REPEAT_DIR}"
REPEAT_DIR="$(cd "${REPEAT_DIR}" && pwd)"

echo "=== Building RepeatModeler database ==="
BuildDatabase -name "${REPEAT_DIR}/${GENOME_LABEL}" "${GENOME}"

WORK_DIR="${TMPDIR_BASE}/repeatmodeler"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

echo "=== Running RepeatModeler ==="
RepeatModeler \
    -database "${REPEAT_DIR}/${GENOME_LABEL}" \
    -threads "${THREADS}" \
    -LTRStruct

echo "=== RepeatModeler complete ==="
echo "Repeat library: ${REPEAT_DIR}/${GENOME_LABEL}-families.fa"
