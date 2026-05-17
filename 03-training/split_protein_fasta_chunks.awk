#!/usr/bin/awk -f
# Split protein FASTA into chunks bounded by max sequences and/or max total
# residues per chunk. A single sequence longer than max_res gets its own chunk
# (warning to stderr).
#
# Variables:
#   max_seqs     max records per chunk; 0 = no limit
#   max_res      max sum of aa length per chunk; 0 = no limit
#   out_prefix   output path prefix → chunk_00001.faa, chunk_00002.faa, ...
#
#   At least one of max_seqs or max_res should be > 0, or everything goes in
#   one chunk (checked in shell).

BEGIN {
    if (out_prefix == "") {
        print "split_protein_fasta_chunks.awk: out_prefix is required" > "/dev/stderr"
        exit 1
    }
    if (max_seqs == "") max_seqs = 0
    if (max_res == "") max_res = 0
    chunk_id = 0
    nseq = 0
    residues = 0
    active = 0
    hdr = ""
    seq = ""
}

/^>/ {
    if (hdr != "") {
        emit_record()
    }
    hdr = $0
    seq = ""
    next
}

{
    seq = seq $0
}

END {
    if (hdr != "") {
        emit_record()
    }
    if (active) {
        close(out)
    }
}

function flush_chunk() {
    if (active) {
        close(out)
        active = 0
        nseq = 0
        residues = 0
    }
}

function open_new_chunk() {
    flush_chunk()
    chunk_id++
    out = sprintf("%s%05d.faa", out_prefix, chunk_id)
    active = 1
}

function write_fasta_record(h, s) {
    print h > out
    for (i = 1; i <= length(s); i += 60) {
        print substr(s, i, 60) > out
    }
}

function emit_record(   len, split_res) {
    gsub(/[[:space:]]/, "", seq)
    len = length(seq)
    if (len == 0) {
        print "WARNING: empty sequence for " hdr > "/dev/stderr"
        hdr = ""
        seq = ""
        return
    }

    if (max_res > 0 && len > max_res) {
        print "WARNING: single protein " len " aa exceeds EXONERATE_CHUNK_MAX_RESIDUES (" max_res "); own chunk." > "/dev/stderr"
        flush_chunk()
        open_new_chunk()
        write_fasta_record(hdr, seq)
        flush_chunk()
        hdr = ""
        seq = ""
        return
    }

    split_res = (max_res > 0 && nseq > 0 && residues + len > max_res)
    if (active && ((max_seqs > 0 && nseq >= max_seqs) || split_res)) {
        flush_chunk()
    }
    if (!active) {
        open_new_chunk()
    }

    write_fasta_record(hdr, seq)
    nseq++
    residues += len
    hdr = ""
    seq = ""
}
