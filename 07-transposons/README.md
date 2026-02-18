# 07 — Transposon analysis

Identify transposon-derived sequences in the predicted protein set and genome
using TransposonPSI. This helps detect false-positive gene predictions that are
actually transposable elements.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_transposonpsi.sh` | TransposonPSI | Detect transposon homology in proteins and genome |

```bash
bash 01_transposonpsi.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/transposons/proteins.TPSI.topHits` | Top transposon hits in predicted proteins |
| `results/transposons/proteins.TPSI.allHits` | All transposon hits in predicted proteins |
| `results/transposons/genome.TPSI.topHits` | Top transposon hits in genome |
| `results/transposons/genome.TPSI.allHits` | All transposon hits in genome |

## Parameter decisions

- **Protein mode** (`prot`): Searches the predicted protein set against PSI-BLAST
  profiles of known transposon families. Hits indicate genes that may be
  mis-annotated transposons and should be flagged or removed from the final
  gene set.
- **Nucleotide mode** (`nuc`): Searches the genome sequence directly. This
  identifies genomic regions with transposon homology that may have been missed
  by RepeatMasker.
- TransposonPSI has no user-tunable parameters beyond the input type; it uses
  a curated set of PSI-BLAST profiles internally.
