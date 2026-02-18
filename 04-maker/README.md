# 04 — MAKER annotation pipeline

Run MAKER to combine trained *ab initio* predictors (AUGUSTUS, SNAP), RNA-seq
evidence, and protein homology into a consensus gene set for *S. solidus*.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_run_maker.sh` | MAKER | Execute the MAKER annotation pipeline |
| `02_filter_results.sh` | custom | Filter for consensus genes (both predictors, AED < 0.5) |

Run in order:

```bash
bash 01_run_maker.sh
bash 02_filter_results.sh
```

## Control files

MAKER uses three control files. Templates are provided in this directory; the
run script fills in paths from `config.sh` before launching MAKER.

| File | Purpose |
|------|---------|
| `maker_opts.ctl` | Main options: genome, evidence, predictors, thresholds |
| `maker_bopts.ctl` | BLAST and Exonerate parameters (defaults are usually fine) |
| `maker_exe.ctl` | Paths to external executables |

To regenerate defaults from your MAKER installation:

```bash
maker -CTL
```

## Outputs

| File | Description |
|------|-------------|
| `results/maker/ssol.maker.output/` | Full MAKER output directory |
| `results/maker/ssol_all.gff` | Merged GFF3 from all contigs |
| `results/maker/ssol_all.maker.proteins.fasta` | Predicted protein sequences |
| `results/maker/ssol_all.maker.transcripts.fasta` | Predicted transcript sequences |
| `results/maker/ssol_filtered.gff` | Filtered gene set (both predictors + AED < 0.5) |
| `results/maker/ssol_filtered.proteins.fasta` | Filtered protein sequences |

## Parameter decisions

### maker_opts.ctl — key fields

| Field | Value | Rationale |
|-------|-------|-----------|
| `genome=` | soft-masked genome | From step 01-repeats |
| `est_gff=` | `results/rnaseq/hints.gff` | Intron hints from STAR/bam2hints |
| `protein=` | combined Swiss-Prot + reference proteins | Homology evidence for gene models |
| `snaphmm=` | `results/training/snap/ssol.hmm` | Trained SNAP model |
| `augustus_species=` | `ssol` | Trained AUGUSTUS species |
| `est2genome=0` | off | Do not build gene models from EST evidence directly |
| `protein2genome=0` | off | Do not build gene models from protein evidence directly |
| `keep_preds=1` | on | Retain *ab initio* predictions even without evidence support |
| `model_org=` | (blank) | Skip internal RepeatMasker — genome is already masked |
| `rmlib=` | (blank) | Already masked; no repeat library needed by MAKER |

Setting `est2genome=0` and `protein2genome=0` means MAKER uses the trained
*ab initio* predictors as the primary gene callers, with EST/protein data
serving only as evidence to score and refine those calls. This is appropriate
after training (step 03).

### Post-hoc filtering (02_filter_results.sh)

Two filters are applied following the paper:

1. **Consensus requirement**: Keep only genes predicted by **both** AUGUSTUS and
   SNAP. MAKER's GFF3 records the `method_name` attribute; the filter requires
   that both `augustus_masked` and `snap_masked` contributed predictions at the
   same locus.
2. **AED threshold < 0.5**: The Annotation Edit Distance measures agreement
   between the gene model and external evidence (0 = perfect, 1 = no support).
   Genes with AED >= 0.5 are considered poorly supported and are removed.
