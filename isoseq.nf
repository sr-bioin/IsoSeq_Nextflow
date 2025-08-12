#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.input_bam = "/Iso-Seq/IsoSeq_Raw_data/m64069_004639.subreads.bam"
params.primers   = "/Iso-Seq/IsoSeq_Raw_data/Isoseq_Barcode_primers.fasta"
params.outdir    = "results"

// Define valid barcode IDs
def valid_ids = [
    "bc1001_5p--bc1001_3p",
    "bc1002_5p--bc1002_3p",
    "bc1003_5p--bc1003_3p"  // Add more as needed
]

// Input channel
Channel
    .fromPath(params.input_bam)
    .map { file -> tuple(file.baseName.replaceAll(/\.subreads$/, ""), file) }
    .set { subreads_ch }

// Step 1: Generate CCS
process ccs {
    tag "$sample_id"
    publishDir "${params.outdir}/ccs", mode: 'copy'

    input:
    tuple val(sample_id), path(subreads)

    output:
    tuple val(sample_id), path("${sample_id}.ccs.bam")

    script:
    """
    ccs $subreads ${sample_id}.ccs.bam --min-passes 1 --min-rq 0.9
    """
}

// Step 2: Demultiplex with lima
process lima {
    tag "$sample_id"
    publishDir "${params.outdir}/lima", mode: 'copy'

    input:
    tuple val(sample_id), path(ccs_bam)

    output:
    tuple val(sample_id), path("${sample_id}.fl.*.bam")

    script:
    """
    lima $ccs_bam ${params.primers} ${sample_id}.fl.bam --isoseq --peek-guess
    """
}

// Step 3: Refine
process refine {
    tag "$barcode_bam"
    publishDir "${params.outdir}/refine", mode: 'copy'

    input:
    tuple val(sample_id), path(barcode_bam)

    output:
    tuple val(sample_id), path("*.flnc.bam")

    script:
    """
    output_name=\$(basename "$barcode_bam" .bam).flnc.bam
    isoseq3 refine "$barcode_bam" ${params.primers} "\$output_name"
    """
}

// Step 4: Cluster with --use-qvs and check for HQ output
process cluster {
    tag "$flnc_bam"
    publishDir "${params.outdir}/cluster", mode: 'copy'

    cpus 30
    memory '32 GB'

    input:
    tuple val(sample_id), path(flnc_bam)

    output:
    tuple val(sample_id), path("*.hq.bam")

    script:
    """
    basename=\$(basename "$flnc_bam" .bam)
    output_prefix="\${basename}_clustered"
    isoseq3 cluster "$flnc_bam" "\${output_prefix}.bam" --use-qvs

    # Sanity check
    if [[ ! -f "\${output_prefix}.hq.bam" ]]; then
        echo "ERROR: HQ BAM not generated for $flnc_bam" >&2
        exit 1
    fi
    """
}

// Step 5: Summarize
process summarize {
    tag "$hq_bam"
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    tuple val(sample_id), path(hq_bam)

    output:
    path("*.summary.csv")

    script:
    """
    set -euo pipefail

    in_file=\$(realpath "$hq_bam")
    base_name=\$(basename "\$in_file" .bam)
    out_file="\${base_name}.summary.csv"

    echo "Running isoseq3 summarize on:"
    echo "  Input : \$in_file"
    echo "  Output: \$out_file"

    isoseq3 summarize "\$in_file" "\$out_file"
    """
}

// Workflow
workflow {
    ccs_out = ccs(subreads_ch)
    lima_out = lima(ccs_out)

    // Flatten and filter based on barcode IDs
    refined = lima_out
        .flatMap { sample_id, bam_files ->
            bam_files.collect { bam_file -> tuple(sample_id, bam_file) }
        }
        .filter { sample_id, bam_file ->
            def name = bam_file.getName()
            name.endsWith(".bam") && valid_ids.any { id -> name.contains(id) }
        }
        | refine

    clustered = cluster(refined)

    hq_bams = clustered.filter { sample_id, file -> file.name.endsWith(".hq.bam") }

    summarize(hq_bams)
}

