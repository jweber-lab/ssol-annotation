# 05 — Functional annotation

Assign putative functions to predicted genes by searching the filtered protein
set against UniProt/Swiss-Prot with BLASTp, then mapping hit descriptions back
onto the GFF3 and FASTA outputs.

## Scripts

| Script | Tool | Purpose |
|--------|------|---------|
| `01_blast_uniprot.sh` | BLASTp, MAKER utilities | Search Swiss-Prot and annotate GFF3 |

```bash
bash 01_blast_uniprot.sh
```

## Outputs

| File | Description |
|------|-------------|
| `results/functional/blastp_sprot.outfmt6` | Tabular BLASTp results |
| `results/functional/ssol_annotated.gff` | GFF3 with Swiss-Prot descriptions added |
| `results/functional/ssol_annotated.proteins.fasta` | Protein FASTA with descriptions |

## Parameter decisions

- **E-value threshold** (`-evalue 1e-5`): Standard threshold for homology
  detection. Lower values (e.g. 1e-10) increase stringency; higher values may
  capture more distant homologs but with more noise.
- **`-max_target_seqs 5`**: Report up to 5 hits per query. The top hit is used
  for the functional description; additional hits provide context.
- **Swiss-Prot vs TrEMBL**: Swiss-Prot (curated, ~570 K entries) is preferred
  for initial annotation because descriptions are manually reviewed. TrEMBL
  (~250 M entries) can be used as a follow-up for genes with no Swiss-Prot hit.
- **MAKER utilities** (`maker_functional_gff`, `maker_functional_fasta`): These
  scripts parse the BLASTp output and add description fields to the GFF3
  `Note=` attribute and FASTA headers, saving manual post-processing.
