# 01 — Repeat identification and masking

Identify and classify repetitive elements *de novo*, then soft-mask the genome
assembly so that downstream gene predictors are not confused by repeats.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_repeatmodeler.sh` | RepeatModeler | Build a *de novo* repeat library from the genome |
| `02_repeatmasker.sh` | RepeatMasker | Classify and soft-mask repeats in the assembly |

Run in order:

```bash
bash 01_repeatmodeler.sh
bash 02_repeatmasker.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/repeats/<label>-families.fa` | Custom repeat library (consensus sequences) |
| `results/repeats/<label>-families.stk` | Stockholm-format seed alignments |
| `results/repeats/<genome>.masked` | Soft-masked genome FASTA (repeats in lowercase) |
| `results/repeats/<genome>.out` | RepeatMasker annotation table |
| `results/repeats/<genome>.tbl` | Summary statistics of repeat content |

## Parameter decisions

### RepeatModeler

- **Engine** (`-engine`): `ncbi` (rmblast) is the default and recommended
  engine. The alternative `wublast` requires a separate license.
- All other parameters use defaults, consistent with Nazarizadeh et al. (2024).
- RepeatModeler internally runs RepeatScout and RECON to detect repeats, then
  classifies them against Dfam. The custom library captures species-specific
  repeat families that are absent from curated databases.

### RepeatMasker

- **Soft-masking** (`-xsmall`): Converts repeat bases to lowercase rather than
  replacing them with Ns. This is critical for MAKER, which can override
  masking when strong evidence (e.g. protein alignment) spans a masked region.
  Hard-masking (`-x`) would permanently hide those regions.
- **Custom library** (`-lib`): Points to the RepeatModeler output. You can
  optionally add `-species cestoda` (or a closer taxon) to also search the
  Dfam/Repbase curated library, but a close cestode-specific library may not
  exist — check `RepeatMasker -species cestoda -help` first.
- **Parallelism** (`-pa`): Number of parallel search jobs. Each job uses ~1 GB
  RAM; set according to available memory.
