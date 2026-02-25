#!/usr/bin/env bash
# config.sh — Global settings for the S. solidus annotation pipeline.
# Source this file from each step script: source "$(dirname "$0")/../config.sh"
set -euo pipefail

# ── Repo root (absolute; all other paths are derived from this) ──────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# ── Conda environment ────────────────────────────────────────────────────────
CONDA_ENV="genome-annotation"
if [[ "${CONDA_DEFAULT_ENV:-}" != "${CONDA_ENV}" ]]; then
    CONDA_BASE="${CONDA_PREFIX:-/opt/conda}"
    [[ -d "${CONDA_BASE}/envs" ]] || CONDA_BASE="$(dirname "${CONDA_BASE}")"
    source "${CONDA_BASE}/etc/profile.d/conda.sh"
    conda activate "${CONDA_ENV}"
fi

# ── Genome assembly ──────────────────────────────────────────────────────────
GENOME_LABEL="ssol"
GENOME="${REPO_ROOT}/../genomes/ssol/cyu-2026-01/ssol-no-rDNA.fa"   # KEEP UPDATED

# ── RNA-seq evidence ─────────────────────────────────────────────────────────
# Directory containing paired-end FASTQ files (*.fastq.gz).
# RNASEQ_DIR="/path/to/rnaseq"                      # UPDATE: path to RNA-seq reads
# RNASEQ_R1=("${RNASEQ_DIR}"/*_R1*.fastq.gz)
# RNASEQ_R2=("${RNASEQ_DIR}"/*_R2*.fastq.gz)

# ── Reference species (proteomes & CDS for training) ────────────────────────
GENOMES_ROOT="${REPO_ROOT}/../genomes/downloads"
REF_LABELS=(lint spro dlat seri hmic egra)

REF_PROTEINS=()
for lbl in "${REF_LABELS[@]}"; do
    REF_PROTEINS+=("${GENOMES_ROOT}/${lbl}/protein.faa")
done

REF_CDS=()
for lbl in "${REF_LABELS[@]}"; do
    REF_CDS+=("${GENOMES_ROOT}/${lbl}/cds_from_genomic.fna")
done

# ── UniProt / Swiss-Prot ─────────────────────────────────────────────────────
UNIPROT_FASTA="/path/to/uniprot_sprot.fasta"       # UPDATE: Swiss-Prot FASTA

# ── Compute resources ────────────────────────────────────────────────────────
THREADS=32

# ── Output directories (all absolute) ────────────────────────────────────────
OUTDIR="${REPO_ROOT}/results"
TMPDIR_BASE="${REPO_ROOT}/temp"
LOG_DIR="${REPO_ROOT}/logs"
mkdir -p "${OUTDIR}" "${TMPDIR_BASE}"

# ── Logging ──────────────────────────────────────────────────────────────────
# Call setup_logging after sourcing this file to tee all stdout/stderr to a
# timestamped log in ./logs/.  Logs are named <script>.<timestamp>.log.
setup_logging() {
    local script_name
    script_name="$(basename "$0" .sh)"
    mkdir -p "${LOG_DIR}"
    LOG_FILE="${LOG_DIR}/${script_name}.$(date +%Y-%m-%d_%H%M%S).log"
    exec > >(tee "${LOG_FILE}") 2>&1
    echo "=== Log: ${LOG_FILE} ==="
    echo "=== Started: $(date) ==="
}
