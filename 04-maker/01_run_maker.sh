#!/usr/bin/env bash
# 01_run_maker.sh — Run the MAKER annotation pipeline.
#
# Fills in the maker_opts.ctl template with paths from config.sh, then
# launches MAKER.
set -euo pipefail
source "$(dirname "$0")/../config.sh"

MAKER_DIR="${OUTDIR}/maker"
mkdir -p "${MAKER_DIR}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASKED_GENOME="${OUTDIR}/repeats/$(basename "${GENOME}").masked"
HINTS_GFF="${OUTDIR}/rnaseq/hints.gff"
SNAP_HMM="${OUTDIR}/training/snap/${GENOME_LABEL}.hmm"
SPECIES="ssol"

# ── Combine protein evidence ─────────────────────────────────────────────────
COMBINED_PROT="${MAKER_DIR}/protein_evidence.faa"
cat "${REF_PROTEINS[@]}" "${UNIPROT_FASTA}" > "${COMBINED_PROT}"
echo "Combined protein evidence: $(grep -c '^>' "${COMBINED_PROT}") sequences."

# ── Fill in maker_opts.ctl ───────────────────────────────────────────────────
OPTS="${MAKER_DIR}/maker_opts.ctl"
cp "${SCRIPT_DIR}/maker_opts.ctl" "${OPTS}"

# Use absolute paths for MAKER.
MASKED_ABS="$(cd "$(dirname "${MASKED_GENOME}")" && pwd)/$(basename "${MASKED_GENOME}")"
HINTS_ABS="$(cd "$(dirname "${HINTS_GFF}")" && pwd)/$(basename "${HINTS_GFF}")"
SNAP_ABS="$(cd "$(dirname "${SNAP_HMM}")" && pwd)/$(basename "${SNAP_HMM}")"
PROT_ABS="$(cd "$(dirname "${COMBINED_PROT}")" && pwd)/$(basename "${COMBINED_PROT}")"

sed -i.bak \
    -e "s|^genome=.*|genome=${MASKED_ABS}|" \
    -e "s|^est_gff=.*|est_gff=${HINTS_ABS}|" \
    -e "s|^protein=.*|protein=${PROT_ABS}|" \
    -e "s|^snaphmm=.*|snaphmm=${SNAP_ABS}|" \
    -e "s|^augustus_species=.*|augustus_species=${SPECIES}|" \
    -e "s|^cpus=.*|cpus=${THREADS}|" \
    "${OPTS}"
rm -f "${OPTS}.bak"

# Copy bopts and exe control files.
cp "${SCRIPT_DIR}/maker_bopts.ctl" "${MAKER_DIR}/maker_bopts.ctl"
cp "${SCRIPT_DIR}/maker_exe.ctl"   "${MAKER_DIR}/maker_exe.ctl"

# ── Run MAKER ────────────────────────────────────────────────────────────────
echo "=== Running MAKER ==="
cd "${MAKER_DIR}"
maker -cpus "${THREADS}" maker_opts.ctl maker_bopts.ctl maker_exe.ctl

# ── Merge outputs ────────────────────────────────────────────────────────────
echo "=== Merging MAKER output ==="
DATASTORE="${MAKER_DIR}/${GENOME_LABEL}.maker.output/${GENOME_LABEL}_master_datastore_index.log"
gff3_merge -d "${DATASTORE}" -o "${MAKER_DIR}/${GENOME_LABEL}_all.gff"
fasta_merge -d "${DATASTORE}" -o "${MAKER_DIR}/${GENOME_LABEL}_all"

echo "=== MAKER complete ==="
echo "GFF3: ${MAKER_DIR}/${GENOME_LABEL}_all.gff"
echo "Proteins: ${MAKER_DIR}/${GENOME_LABEL}_all.all.maker.proteins.fasta"
echo "Transcripts: ${MAKER_DIR}/${GENOME_LABEL}_all.all.maker.transcripts.fasta"
