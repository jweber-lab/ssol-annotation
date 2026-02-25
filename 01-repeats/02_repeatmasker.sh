#!/usr/bin/env bash
# 02_repeatmasker.sh — Soft-mask the genome using the de novo repeat library.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

REPEAT_DIR="${OUTDIR}/repeats"
REPEAT_LIB="${REPEAT_DIR}/${GENOME_LABEL}-families.fa"

if [[ ! -f "${REPEAT_LIB}" ]]; then
    echo "ERROR: Repeat library not found: ${REPEAT_LIB}"
    echo "Run 01_repeatmodeler.sh first."
    exit 1
fi

echo "=== Running RepeatMasker ==="
RepeatMasker \
    -lib "${REPEAT_LIB}" \
    -xsmall \
    -pa "${THREADS}" \
    -gff \
    -dir "${REPEAT_DIR}" \
    "${GENOME}"

echo "=== RepeatMasker complete ==="
echo "Masked genome: ${REPEAT_DIR}/$(basename "${GENOME}").masked"
echo "Summary table: ${REPEAT_DIR}/$(basename "${GENOME}").tbl"
