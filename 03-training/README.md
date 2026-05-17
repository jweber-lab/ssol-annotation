# 03 — Gene predictor training

Train AUGUSTUS and SNAP *ab initio* gene predictors using coding sequences from
six reference cestode species aligned to the repeat-masked *S. solidus* genome.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_train_augustus.sh` | AUGUSTUS | Train a species-specific AUGUSTUS HMM via the manual workflow |
| `split_protein_fasta_chunks.awk` | awk | Split combined protein FASTA for bounded exonerate jobs |
| `02_train_snap.sh` | SNAP | Train a SNAP HMM from the same evidence set |

Run in order:

```bash
bash 01_train_augustus.sh
bash 02_train_snap.sh
```

## Outputs

| File | Description |
|------|-------------|
| `$AUGUSTUS_CONFIG_PATH/species/ssol/` | Trained AUGUSTUS species parameters |
| `results/training/snap/ssol.hmm` | Trained SNAP HMM file |
| `results/training/augustus/training_genes.gff` | Training gene set (GFF) used by AUGUSTUS and SNAP |
| `temp/augustus/exonerate_chunks/` | Per-chunk FASTA and GFF from exonerate (when chunking enabled) |

## Approach

Reference protein sequences from the reference cestode proteomes are aligned to
the repeat-masked genome with **exonerate** (`protein2genome`) to produce gene
structure predictions. High-quality, non-overlapping gene models are selected
as the training set. Both AUGUSTUS and SNAP are trained on this same set so
that downstream MAKER consensus filtering (requiring both predictors) is
meaningful.

### Exonerate chunking (memory)

Aligning tens of thousands of proteins in **one** exonerate process can exhaust
RAM (hundreds of GB). In `config.sh`, set:

- **`EXONERATE_CHUNK_MAX_SEQS`** — maximum protein sequences per chunk (e.g.
  `5000`). Use `0` for no limit on count.
- **`EXONERATE_CHUNK_MAX_RESIDUES`** — maximum **total amino-acid length** per
  chunk (e.g. `3000000`). Prevents a chunk of few but huge proteins from
  blowing memory. Use `0` for no limit on residues.

If **both** are `0`, chunking is disabled and exonerate runs once on the full
combined FASTA (only appropriate for small reference sets).

Chunking workflow: `split_protein_fasta_chunks.awk` writes
`temp/augustus/exonerate_chunks/chunk_*.faa` → one exonerate run per chunk → GFF
outputs are merged (single `##gff-version 2`, `#` headers preserved, feature
lines sorted by contig and coordinates) into
`results/training/augustus/exonerate_hits.gff`.

**Edge case:** any single protein longer than `EXONERATE_CHUNK_MAX_RESIDUES`
is placed alone in its own chunk and a warning is printed (the sequence cannot be
split across exonerate jobs).

### Alternative: MAKER iterative training

Instead of standalone training, you can bootstrap through MAKER:

1. Run MAKER round 1 with default predictor parameters (no trained model).
2. Extract high-quality gene models from the round 1 output (AED < 0.25).
3. Train AUGUSTUS and SNAP on those models.
4. Run MAKER round 2 with the trained models.

This approach can be more practical because it lets MAKER handle the evidence
integration. The scripts here implement the standalone approach from the paper;
switch to the iterative approach by running `04-maker/01_run_maker.sh` first
with `augustus_species=` set to a generic model (e.g. `caenorhabditis`), then
retraining.

## Parameter decisions

### AUGUSTUS

- **`new_species.pl --species=ssol`**: Creates a new species parameter directory.
- **`etraining --species=ssol`**: Trains the model on the training gene GFF/GB.
- **`optimize_augustus.pl --species=ssol --rounds=6`**: Optimizes
  meta-parameters over six rounds, matching the source paper. Each round
  takes hours; increase `--cpus` to parallelise (default 1).
- The training set should contain 200-1000 gene models with complete start/stop
  codons. Fewer than ~200 genes may produce an unreliable model.
- If an existing AUGUSTUS species is close (e.g. `schistosoma` or a generic
  flatworm), set it as `--AUGUSTUS_CONFIG_PATH` template to warm-start.

### SNAP

- **`fathom`**: Validates training genes and splits into training/test sets.
  Use `fathom -categorize 1000` to ensure flanking sequence around each gene.
- **`forge`**: Builds the signal and content models.
- **`hmm-assembler.pl`**: Assembles the final HMM from forge output.
- SNAP is less configurable than AUGUSTUS; the main quality lever is the
  training gene set itself.
