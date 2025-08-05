#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.input_bam = "/home/Iso-Seq/IsoSeq_Raw_data/m64069_004639.subreads.bam"
params.primers   = "/home/Iso-Seq/IsoSeq_Raw_data/Isoseq_Barcode_primers.fasta"
params.outdir    = "results"

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

// Step 3: Refine each demultiplexed BAM separately
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

// Step 4: Cluster
process cluster {
    tag "$flnc_bam"
    publishDir "${params.outdir}/cluster", mode: 'copy'

    cpus 20
    memory '32 GB'
    
    input:
    tuple val(sample_id), path(flnc_bam)

    output:
    tuple val(sample_id), path("${flnc_bam.baseName}_clustered.hq.bam"), path("${flnc_bam.baseName}_clustered.hq.bam.pbi")

    script:
    """
    # First check if input file exists and has content
    if [ ! -s "$flnc_bam" ]; then
        echo "Error: Input file $flnc_bam is empty or missing"
        exit 1
    fi
    
    isoseq3 cluster "$flnc_bam" "${flnc_bam.baseName}_clustered.bam"
    
    # Check if output was generated
    if [ ! -s "${flnc_bam.baseName}_clustered.hq.bam" ]; then
        echo "Error: No HQ output generated for $flnc_bam"
        exit 1
    fi
    """
}

// Step 5: Summarize
process summarize {
    tag "$polished_bam"
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    tuple val(sample_id), path(hq_bam), path(pbi)

    output:
    path("*.summary.txt")

    script:
    """
    output_name=\$(basename "$hq_bam" .bam).summary.txt
    isoseq3 summarize "$hq_bam" "\$output_name"
    """
}

// Workflow
workflow {
    ccs_out = ccs(subreads_ch)
    lima_out = lima(ccs_out)

    refined = lima_out
        .flatMap { sample_id, bam_files ->
            bam_files.collect { bam_file -> tuple(sample_id, bam_file) }
        }
        .filter { sample_id, bam_file ->
            def name = bam_file.getName()
            name.endsWith(".bam") && (
                name.contains("bc1001_5p--bc1001_3p") ||
                name.contains("bc1002_5p--bc1002_3p")
            )
        }
        | refine

    clustered = cluster(refined)
    summarize(clustered)
}
