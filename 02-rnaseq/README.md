# 02 — RNA-seq alignment and intron hints

Align RNA-seq reads to the genome with STAR (two-pass mode) and extract intron
hints for AUGUSTUS/MAKER using `bam2hints`.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_star_index.sh` | STAR | Build genome index for alignment |
| `02_star_align.sh` | STAR | Two-pass splice-aware alignment |
| `03_bam2hints.sh` | AUGUSTUS bam2hints | Extract intron hints from aligned BAM |

Run in order:

```bash
bash 01_star_index.sh
bash 02_star_align.sh
bash 03_bam2hints.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/rnaseq/star_index/` | STAR genome index directory |
| `results/rnaseq/star_align/Aligned.sortedByCoord.out.bam` | Coordinate-sorted alignment |
| `results/rnaseq/star_align/SJ.out.tab` | Splice junction table |
| `results/rnaseq/hints.gff` | Intron hints in GFF for AUGUSTUS/MAKER |

## Parameter decisions

### STAR genome index

- **`--genomeSAindexNbases`**: Must be scaled for genome size. The default (14)
  is calibrated for human (~3 Gb). For the *S. solidus* genome (~540 Mb), use
  `min(14, floor(log2(genome_length)/2 - 1))` which gives approximately 13.
  The script computes this automatically from the assembly.
- The **unmasked** genome is used for indexing; STAR handles multi-mapped reads
  from repeats via its own internal logic.

### STAR alignment

- **`--twopassMode Basic`**: First pass discovers novel splice junctions;
  second pass re-maps using the expanded junction set. This matches the paper's
  two-pass approach and improves sensitivity for novel transcripts.
- **`--sjdbOverhang`**: Ideally read length - 1 (e.g. 149 for 150 bp reads).
  The script defaults to 149; adjust in `config.sh` or the script if your
  reads differ.
- **`--outSAMtype BAM SortedByCoordinate`**: Produces a coordinate-sorted BAM
  directly, avoiding a separate samtools sort step.
- **`--outFilterMultimapNmax 20`**: Allows up to 20 multi-mapping locations
  (STAR default). For annotation purposes, keeping some multi-mappers provides
  coverage in recently duplicated genes.

### bam2hints

- **`--intronsonly`**: Extracts only intron (splice junction) hints. These are
  the primary evidence type AUGUSTUS uses from RNA-seq within MAKER.
- The hints GFF is passed to MAKER via the `est_gff=` field in
  `maker_opts.ctl`, or can be used directly with standalone AUGUSTUS via
  `--hintsfile`.
