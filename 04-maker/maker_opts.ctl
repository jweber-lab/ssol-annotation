#-----Genome (required)
genome=                           # FILLED BY 01_run_maker.sh
organism_type=eukaryotic

#-----Re-annotation Using MAKER Derived GFF3
maker_gff=
est_pass=0
altest_pass=0
protein_pass=0
rm_pass=0
model_pass=0
pred_pass=0
other_pass=0

#-----EST Evidence (for best results provide a file for at least one)
est=
altest=
est_gff=                          # FILLED: intron hints from bam2hints

#-----Protein Homology Evidence (for best results provide a file for at least one)
protein=                          # FILLED: Swiss-Prot + reference proteins
protein_gff=

#-----Repeat Masking (leave blank — genome is pre-masked)
model_org=
rmlib=
repeat_protein=
rm_gff=
prok_rm=0
softmask=1

#-----Gene Prediction
snaphmm=                          # FILLED: trained SNAP HMM
gmhmm=
augustus_species=                  # FILLED: trained AUGUSTUS species name
fgenesh_par_file=
pred_gff=
model_gff=
run_evm=0
est2genome=0
protein2genome=0
trna=0
snoscan_rrna=
snoscan_meth=
unmask=0
allow_resolve_overlaps=

#-----Other Annotation Feature Types (features MAKER doesn't recognize)
other_gff=

#-----External Application Behavior Options
alt_peptide=C
cpus=1

#-----MAKER Behavior Options
max_dna_len=100000
min_contig=1
pred_flank=200
pred_stats=0
AED_threshold=1
min_protein=0
alt_splice=0
always_complete=0
map_forward=0
keep_preds=1
split_hit=10000
single_exon=0
single_length=250
correct_est_fusion=0
tries=2
clean_try=0
clean_up=0
TMP=
