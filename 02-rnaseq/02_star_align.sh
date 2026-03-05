#!/usr/bin/env bash
# 02_star_align.sh — Two-pass STAR alignment of RNA-seq reads.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

INDEX_DIR="${OUTDIR}/rnaseq/star_index"
ALIGN_DIR="${OUTDIR}/rnaseq/star_align"
mkdir -p "${ALIGN_DIR}"

SJDB_OVERHANG=149   # read length - 1; adjust for your data

if [[ -z "${RNASEQ_R1+x}" ]] || (( ${#RNASEQ_R1[@]} == 0 )); then
    echo "ERROR: RNASEQ_R1 is not set or empty."
    echo "Uncomment and set RNASEQ_DIR in config.sh first."
    exit 1
fi

# Comma-separate multiple FASTQ files if present.
R1=$(IFS=,; echo "${RNASEQ_R1[*]}")
R2=$(IFS=,; echo "${RNASEQ_R2[*]}")

STAR_TMP="${TMPDIR_BASE}/star"
mkdir -p "${STAR_TMP}"

echo "=== Running STAR two-pass alignment ==="
STAR \
    --runMode alignReads \
    --runThreadN "${THREADS}" \
    --genomeDir "${INDEX_DIR}" \
    --readFilesIn "${R1}" "${R2}" \
    --readFilesCommand zcat \
    --twopassMode Basic \
    --sjdbOverhang "${SJDB_OVERHANG}" \
    --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix "${ALIGN_DIR}/" \
    --outTmpDir "${STAR_TMP}/align" \
    --outFilterMultimapNmax 20

echo "=== Indexing BAM ==="
samtools index "${ALIGN_DIR}/Aligned.sortedByCoord.out.bam"

echo "=== STAR alignment complete ==="
echo "BAM: ${ALIGN_DIR}/Aligned.sortedByCoord.out.bam"
echo "Splice junctions: ${ALIGN_DIR}/SJ.out.tab"
