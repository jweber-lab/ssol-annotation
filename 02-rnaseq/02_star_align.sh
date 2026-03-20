#!/usr/bin/env bash
# 02_star_align.sh — Two-pass STAR alignment of RNA-seq reads.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

INDEX_DIR="${OUTDIR}/rnaseq/star_index"
ALIGN_DIR="${OUTDIR}/rnaseq/star_align"
mkdir -p "${ALIGN_DIR}"

SJDB_OVERHANG=149   # read length - 1; adjust for your data

# Re-scan RNASEQ_DIR here (nullglob) so we never pass empty STAR args when globs
# fail in config.sh or RNASEQ_DIR is wrong on this host.
if [[ -z "${RNASEQ_DIR:-}" ]]; then
    echo "ERROR: RNASEQ_DIR is not set in config.sh."
    exit 1
fi
if [[ ! -d "${RNASEQ_DIR}" ]]; then
    echo "ERROR: RNASEQ_DIR is not a directory: ${RNASEQ_DIR}"
    exit 1
fi

shopt -s nullglob
R1_FILES=("${RNASEQ_DIR}"/*_1.fastq.gz)
R2_FILES=("${RNASEQ_DIR}"/*_2.fastq.gz)
shopt -u nullglob

n1=${#R1_FILES[@]}
n2=${#R2_FILES[@]}
if (( n1 == 0 || n2 == 0 )); then
    echo "ERROR: No FASTQ pairs found under RNASEQ_DIR=${RNASEQ_DIR}"
    echo "Expected files matching *_1.fastq.gz and *_2.fastq.gz (e.g. SRR123_1.fastq.gz)."
    echo "Directory listing (first 20 entries):"
    ls -la "${RNASEQ_DIR}" | head -20
    exit 1
fi
if (( n1 != n2 )); then
    echo "ERROR: Mismatched R1/R2 counts: ${n1} *_1 vs ${n2} *_2 under ${RNASEQ_DIR}"
    exit 1
fi

# Stable sort so R1/R2 lists stay in matching order across many samples.
mapfile -t R1_FILES < <(printf '%s\n' "${R1_FILES[@]}" | sort)
mapfile -t R2_FILES < <(printf '%s\n' "${R2_FILES[@]}" | sort)

echo "Found ${n1} paired FASTQ file set(s). First R1: ${R1_FILES[0]}"

# Comma-separate for STAR (mate1 list, mate2 list).
R1=$(IFS=,; echo "${R1_FILES[*]}")
R2=$(IFS=,; echo "${R2_FILES[*]}")

STAR_TMP="${TMPDIR_BASE}/star"
mkdir -p "${STAR_TMP}"

echo "=== Running STAR two-pass alignment ==="
# Use Unsorted BAM here: STAR's internal coordinate sort opens many temp files
# (BAMsort/*) and often hits ulimit -n with many threads / large merges. Sort with
# samtools instead; downstream still sees Aligned.sortedByCoord.out.bam.
STAR \
    --runMode alignReads \
    --runThreadN "${THREADS}" \
    --genomeDir "${INDEX_DIR}" \
    --readFilesIn "${R1}" "${R2}" \
    --readFilesCommand zcat \
    --twopassMode Basic \
    --sjdbOverhang "${SJDB_OVERHANG}" \
    --outSAMtype BAM Unsorted \
    --outFileNamePrefix "${ALIGN_DIR}/" \
    --outTmpDir "${STAR_TMP}/align" \
    --outFilterMultimapNmax 20

UNSORTED_BAM="${ALIGN_DIR}/Aligned.out.bam"
SORTED_BAM="${ALIGN_DIR}/Aligned.sortedByCoord.out.bam"
if [[ ! -f "${UNSORTED_BAM}" ]]; then
    echo "ERROR: STAR did not produce ${UNSORTED_BAM}"
    exit 1
fi

mkdir -p "${STAR_TMP}/sort"
echo "=== Sorting BAM with samtools (coordinate) ==="
samtools sort -@ "${THREADS}" -T "${STAR_TMP}/sort/st" -o "${SORTED_BAM}" "${UNSORTED_BAM}"
rm -f "${UNSORTED_BAM}"

echo "=== Indexing BAM ==="
samtools index "${SORTED_BAM}"

echo "=== STAR alignment complete ==="
echo "BAM: ${ALIGN_DIR}/Aligned.sortedByCoord.out.bam"
echo "Splice junctions: ${ALIGN_DIR}/SJ.out.tab"
