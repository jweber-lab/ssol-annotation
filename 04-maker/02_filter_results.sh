#!/usr/bin/env bash
# 02_filter_results.sh — Filter MAKER output for high-confidence genes.
#
# Two filters (from Nazarizadeh et al.):
#   1. Consensus: gene must be predicted by both AUGUSTUS and SNAP.
#   2. AED < 0.5: gene must have strong evidence support.
set -euo pipefail
source "$(dirname "$0")/../config.sh"

MAKER_DIR="${OUTDIR}/maker"
ALL_GFF="${MAKER_DIR}/${GENOME_LABEL}_all.gff"
ALL_PROT="${MAKER_DIR}/${GENOME_LABEL}_all.all.maker.proteins.fasta"
FILTERED_GFF="${MAKER_DIR}/${GENOME_LABEL}_filtered.gff"
FILTERED_PROT="${MAKER_DIR}/${GENOME_LABEL}_filtered.proteins.fasta"

AED_CUTOFF=0.5

if [[ ! -f "${ALL_GFF}" ]]; then
    echo "ERROR: Merged GFF not found: ${ALL_GFF}"
    echo "Run 01_run_maker.sh first."
    exit 1
fi

echo "=== Filtering MAKER results ==="

# ── 1. Extract gene IDs predicted by both AUGUSTUS and SNAP ──────────────────
# MAKER GFF3 contains child features with method source columns.  Identify
# mRNA IDs whose parent gene locus was called by both predictors.

# Collect loci with AUGUSTUS support.
AUG_LOCI=$(awk -F'\t' '$2 ~ /augustus/ && $3 == "mRNA" {
    match($9, /Parent=([^;]+)/, a); print a[1]
}' "${ALL_GFF}" | sort -u)

# Collect loci with SNAP support.
SNAP_LOCI=$(awk -F'\t' '$2 ~ /snap/ && $3 == "mRNA" {
    match($9, /Parent=([^;]+)/, a); print a[1]
}' "${ALL_GFF}" | sort -u)

# Intersect: loci predicted by both.
CONSENSUS_LOCI=$(comm -12 <(echo "${AUG_LOCI}") <(echo "${SNAP_LOCI}"))
CONSENSUS_COUNT=$(echo "${CONSENSUS_LOCI}" | grep -c . || true)
echo "Consensus loci (both AUGUSTUS + SNAP): ${CONSENSUS_COUNT}"

# ── 2. Apply AED threshold ──────────────────────────────────────────────────
# Write filtered GFF: keep header lines, and gene/mRNA/exon/CDS features whose
# gene locus is in the consensus set and whose AED < cutoff.

awk -F'\t' -v cutoff="${AED_CUTOFF}" -v loci="${CONSENSUS_LOCI}" '
BEGIN {
    split(loci, arr, "\n")
    for (i in arr) keep[arr[i]] = 1
}
/^#/ { print; next }
{
    parent = ""
    aed = 1.0
    if (match($9, /Parent=([^;]+)/, m)) parent = m[1]
    if (match($9, /ID=([^;]+)/, m2)) {
        if (parent == "") parent = m2[1]
    }
    if (match($9, /_AED=([^;]+)/, m3)) aed = m3[1] + 0

    # For gene-level features, use ID as locus name.
    if ($3 == "gene") {
        match($9, /ID=([^;]+)/, gid)
        if (gid[1] in keep && aed < cutoff) print
        next
    }

    # For sub-features, check parent.
    if (parent in keep && aed < cutoff) print
}
' "${ALL_GFF}" > "${FILTERED_GFF}"

GENE_COUNT=$(grep -cP '\tgene\t' "${FILTERED_GFF}" || true)
echo "Filtered genes (AED < ${AED_CUTOFF}): ${GENE_COUNT}"

# ── 3. Extract corresponding protein sequences ──────────────────────────────
# Pull mRNA IDs from filtered GFF, then extract matching FASTA entries.
MRNA_IDS=$(awk -F'\t' '$3 == "mRNA" { match($9, /ID=([^;]+)/, m); print m[1] }' \
    "${FILTERED_GFF}")

# Use awk to extract matching FASTA records.
awk -v ids="${MRNA_IDS}" '
BEGIN { split(ids, arr, "\n"); for (i in arr) keep[">" arr[i]] = 1 }
/^>/ { p = ($1 in keep) }
p { print }
' "${ALL_PROT}" > "${FILTERED_PROT}"

PROT_COUNT=$(grep -c '^>' "${FILTERED_PROT}" || true)

echo "=== Filtering complete ==="
echo "Filtered GFF3: ${FILTERED_GFF} (${GENE_COUNT} genes)"
echo "Filtered proteins: ${FILTERED_PROT} (${PROT_COUNT} sequences)"
