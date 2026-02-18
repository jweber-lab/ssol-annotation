#!/usr/bin/env bash
# config.sh — Global settings for the S. solidus annotation pipeline.
# Source this file from each step script: source "$(dirname "$0")/../config.sh"
set -euo pipefail

# ── Genome assembly ──────────────────────────────────────────────────────────
GENOME_LABEL="ssol"
GENOME="../genomes/ssol/cyu-2026-01/ssol-no-rDNA.fa"   # KEEP UPDATED: path to S. solidus assembly

# ── RNA-seq evidence ─────────────────────────────────────────────────────────
# Directory containing paired-end FASTQ files (*.fastq.gz).
RNASEQ_DIR="/path/to/rnaseq"                      # UPDATE: path to RNA-seq reads
RNASEQ_R1=("${RNASEQ_DIR}"/*_R1*.fastq.gz)
RNASEQ_R2=("${RNASEQ_DIR}"/*_R2*.fastq.gz)

# ── Reference species (proteomes & CDS for training) ────────────────────────
GENOMES_ROOT="../genomes/downloads"
REF_LABELS=(lint spro dlat seri hmic egra)

# Collect protein FASTA paths from the genomes directory.
REF_PROTEINS=()
for lbl in "${REF_LABELS[@]}"; do
    REF_PROTEINS+=("${GENOMES_ROOT}/${lbl}/protein.faa")
done

# Collect CDS nucleotide FASTA paths (used for AUGUSTUS/SNAP training).
REF_CDS=()
for lbl in "${REF_LABELS[@]}"; do
    REF_CDS+=("${GENOMES_ROOT}/${lbl}/cds_from_genomic.fna")
done

# ── UniProt / Swiss-Prot ─────────────────────────────────────────────────────
UNIPROT_FASTA="/path/to/uniprot_sprot.fasta"       # UPDATE: Swiss-Prot FASTA

# ── Compute resources ────────────────────────────────────────────────────────
THREADS=8

# ── Output directories ───────────────────────────────────────────────────────
OUTDIR="results"
mkdir -p "${OUTDIR}"
