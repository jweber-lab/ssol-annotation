#!/usr/bin/env bash
# 01_tsa_vs_genome.sh — Validate genome and annotation against TSA transcripts.
set -euo pipefail
source "$(dirname "$0")/../config.sh"
setup_logging

if [[ "${RUN_TSA_VALIDATION}" != "true" ]]; then
    echo "RUN_TSA_VALIDATION=false in config.sh — skipping TSA validation."
    exit 0
fi

if [[ ! -f "${TSA_FASTA}" ]]; then
    echo "ERROR: TSA_FASTA not found: ${TSA_FASTA}"
    echo "Update TSA_FASTA in config.sh to the Hebert 2016 TSA nucleotide FASTA."
    exit 1
fi

VAL_DIR="${OUTDIR}/validation"
mkdir -p "${VAL_DIR}"

GENOME_DB="${VAL_DIR}/genome_tsa_db"
BLAST_OUT="${VAL_DIR}/tsa_vs_genome.blastn.outfmt6"
SUMMARY_TSV="${VAL_DIR}/tsa_covered.tsv"
UNMAPPED_FASTA="${VAL_DIR}/tsa_unmapped.fasta"

echo "=== Building BLASTn genome database for TSA validation ==="
if [[ ! -f "${GENOME_DB}.nhr" ]]; then
    makeblastdb \
        -in "${GENOME}" \
        -dbtype nucl \
        -out "${GENOME_DB}" \
        -parse_seqids
fi

echo "=== Running BLASTn TSA vs genome (megablast) ==="
blastn \
    -task megablast \
    -query "${TSA_FASTA}" \
    -db "${GENOME_DB}" \
    -evalue 1e-20 \
    -max_target_seqs 5 \
    -outfmt "6 qseqid sseqid pident length qlen slen qstart qend sstart send evalue bitscore" \
    -num_threads "${THREADS}" \
    -out "${BLAST_OUT}"

echo "=== Summarising TSA coverage per transcript ==="
awk '
BEGIN { OFS = "\t" }
{
    q = $1; pident = $3; alen = $4; qlen = $5;
    cov = alen / qlen;
    key = q;
    if (!(key in best) || alen > best_len[key]) {
        best_len[key] = alen;
        best_pident[key] = pident;
        best_cov[key] = cov;
    }
}
END {
    print "transcript_id", "best_identity", "best_coverage";
    for (q in best_len) {
        print q, best_pident[q], best_cov[q];
    }
}
' "${BLAST_OUT}" > "${SUMMARY_TSV}"

echo "=== Extracting unmapped / weakly mapped TSA transcripts ==="
awk 'NR==1 { next } ($2 < 95 || $3 < 0.8) { print $1 }' "${SUMMARY_TSV}" | sort -u > "${VAL_DIR}/tsa_unmapped.ids"

if command -v seqtk >/dev/null 2>&1; then
    seqtk subseq "${TSA_FASTA}" "${VAL_DIR}/tsa_unmapped.ids" > "${UNMAPPED_FASTA}" || true
else
    echo "NOTE: seqtk not found; unmapped FASTA will not be extracted. IDs are in ${VAL_DIR}/tsa_unmapped.ids"
fi

UNMAPPED_COUNT=$(wc -l < "${VAL_DIR}/tsa_unmapped.ids" || echo 0)
TOTAL_TSA=$(grep -c "^>" "${TSA_FASTA}" || echo 0)

echo "=== TSA validation summary ==="
echo "Total TSA transcripts: ${TOTAL_TSA}"
echo "Unmapped / weakly mapped transcripts (pident < 95% or cov < 0.8): ${UNMAPPED_COUNT}"
echo "BLAST output: ${BLAST_OUT}"
echo "Per-transcript summary: ${SUMMARY_TSV}"
echo "Unmapped IDs: ${VAL_DIR}/tsa_unmapped.ids"
echo "Unmapped FASTA (if seqtk available): ${UNMAPPED_FASTA}"

