# 06 — Non-coding RNA prediction

Predict tRNA genes in the *S. solidus* genome using tRNAscan-SE.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_trnascan.sh` | tRNAscan-SE | Predict tRNA genes genome-wide |

```bash
bash 01_trnascan.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/ncrna/trnascan.out` | Tabular tRNA predictions |
| `results/ncrna/trnascan.gff3` | tRNA predictions in GFF3 format |
| `results/ncrna/trnascan.stats` | Summary statistics |
| `results/ncrna/trnascan.ss` | Secondary structure predictions |

## Parameter decisions

- **Search mode**: `-E` (eukaryotic) is the appropriate mode for *S. solidus*.
  Use `-O` (organellar) for mitochondrial tRNAs if the assembly includes the
  mitogenome.
- tRNAscan-SE uses a combination of tRNAscan 1.4, Infernal covariance models,
  and EufindtRNA to maximise sensitivity and specificity. Default thresholds
  are well-validated and should not need adjustment for typical eukaryotic
  genomes.
- The GFF3 output can be merged with the MAKER GFF3 for a comprehensive
  annotation.
