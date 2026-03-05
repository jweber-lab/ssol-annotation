# 08 — TSA vs genome validation

Use the Hebert 2016 TSA (transcriptome shotgun assembly) as an independent
check on genome completeness and the MAKER gene set.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_tsa_vs_genome.sh` | BLASTn, bedtools | Map TSA transcripts to the genome and summarise support |

```bash
bash 01_tsa_vs_genome.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/validation/tsa_vs_genome.blastn.outfmt6` | BLASTn alignments TSA → genome |
| `results/validation/tsa_covered.tsv` | Per-transcript coverage / identity summary |
| `results/validation/tsa_unmapped.fasta` | TSA transcripts with no good genomic hit |

## Parameter decisions

- **BLASTn vs genome**: Uses `blastn -task megablast` against the *unmasked*
  genome. This is faster and more sensitive for near-identical genomic matches
  than exon-wise alignment with spliced mappers.
- **Hit filtering**: Only alignments with identity ≥ 95 % and coverage ≥ 80 %
  of the transcript length are counted as \"supported\". These thresholds flag
  potential misassemblies or missing loci without over-penalising alternative
  isoforms.
- **Optional**: if `RUN_TSA_VALIDATION` in `config.sh` is `false`, the script
  exits immediately after printing a message. Set it to `true` to enable this
  step.

