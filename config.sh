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
RNASEQ_DIR="/work/shared/transcriptomes/hebert-2016/PRJNA304161/SRP066813"
RNASEQ_R1=("${RNASEQ_DIR}"/*_1.fastq.gz)
RNASEQ_R2=("${RNASEQ_DIR}"/*_2.fastq.gz)

# ── TSA (transcriptome shotgun assembly) evidence (Hebert 2016) ──────────────
# Nucleotide TSA FASTA for S. solidus transcripts (EST-like evidence).
TSA_FASTA="${REPO_ROOT}/../transcriptomes/hebert-2016/PRJNA304161/GEEE01/GEEE01.1.fsa_nt.gz"

# Predicted proteins from TSA (same-species protein evidence).
TSA_PROTEINS="${REPO_ROOT}/../transcriptomes/hebert-2016/PRJNA304161/GEEE01/GEEE01.1.fsa_aa.gz"

# ── Reference species (proteomes & CDS for training) ────────────────────────

REF_PROTEINS=(
    "${REPO_ROOT}/../genomes/downloads/spro/ncbi_dataset/data/GCA_053814205.1/protein.faa"
    "${REPO_ROOT}/../genomes/downloads/dlat/wormbase_parasite/dibothriocephalus_latus.PRJEB1206.WBPS19.protein.fa"
    "${REPO_ROOT}/../genomes/downloads/seri/wormbase_parasite/spirometra_erinaceieuropaei.PRJEB1202.WBPS19.protein.fa"
    "${REPO_ROOT}/../genomes/downloads/hmic/wormbase_parasite/hymenolepis_microstoma.PRJEB124.WBPS19.protein.fa"
    "${REPO_ROOT}/../genomes/downloads/egra/wormbase_parasite/echinococcus_granulosus.PRJNA754835.WBPS19.protein.fa"
)
REF_CDS=(
    "${REPO_ROOT}/../genomes/downloads/spro/ncbi_dataset/data/GCA_053814205.1/cds_from_genomic.fna"
    "${REPO_ROOT}/../genomes/downloads/dlat/ncbi_dataset/data/GCA_900617775.1/cds_from_genomic.fna"
    "${REPO_ROOT}/../genomes/downloads/seri/ncbi_dataset/data/GCA_000951995.1/cds_from_genomic.fna"
    "${REPO_ROOT}/../genomes/downloads/hmic/ncbi_dataset/data/GCA_000469805.3/cds_from_genomic.fna"
    "${REPO_ROOT}/../genomes/downloads/egra/ncbi_dataset/data/GCA_021556725.1/cds_from_genomic.fna"
)



# GENOMES_ROOT="${REPO_ROOT}/../genomes/downloads"
# REF_LABELS=(lint spro dlat seri hmic egra)
# ASSEMBLY_IDS=(GCA_036362985.1 GCA_053814205.1 GCA_900617775.1 GCA_000951995.1 GCA_000469805.3 GCA_021556725.1)

# REF_PROTEINS=()
# for i in "${!REF_LABELS[@]}"; do
#     REF_PROTEINS+=("${GENOMES_ROOT}/${REF_LABELS[${i}]}/ncbi_dataset/data/${ASSEMBLY_IDS[${i}]}/protein.faa")
# done

# REF_CDS=()
# for i in "${!REF_LABELS[@]}"; do
#     REF_CDS+=("${GENOMES_ROOT}/${REF_LABELS[${i}]}/ncbi_dataset/data/${ASSEMBLY_IDS[${i}]}/cds_from_genomic.fna")
# done

# ── UniProt / Swiss-Prot ─────────────────────────────────────────────────────
UNIPROT_FASTA="/path/to/uniprot_sprot.fasta"       # UPDATE: Swiss-Prot FASTA

# ── Compute resources ────────────────────────────────────────────────────────
THREADS=32

# ── AUGUSTUS training: exonerate chunking (memory / runtime) ─────────────────
# Split combined reference proteins into chunk FASTAs, run exonerate per
# chunk, then merge GFFs. Limits peak RAM vs one 100k+ protein exonerate job.
# Set both to 0 to disable chunking (single exonerate on the full COMBINED_PROT).
EXONERATE_CHUNK_MAX_SEQS=5000
EXONERATE_CHUNK_MAX_RESIDUES=3000000

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
