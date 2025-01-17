#!/usr/bin/env nextflow

// Specify DSL2
nextflow.enable.dsl=2

// Process definition
process pilon {
    label "avg_cores"
    label "avg_mem"
    label "regular_queue"

    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy",
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container "biocontainers/pilon:v1.23dfsg-1-deb_cv1"
    containerOptions '-u \$(id -u):\$(id -g) -v "$PWD":/data'

    input:
        val opts
        tuple val(meta), path(fasta)
        tuple val(meta), path(bam), path(bai)

    output:
        tuple val(meta), path("*.fasta"), emit: fasta
        tuple val(meta), path("*.wig"), emit: wig
        tuple val(meta), path("*.vcf"), emit: vcf

    script:

    args = ""
    if(opts.args) {
        ext_args = opts.args
        args += ext_args.trim()
    }

    pilon_command = "pilon $args --threads ${task.cpus} --fix ${opts.fix} --vcf --tracks --genome ${fasta} --bam ${bam} --output ${fasta.simpleName}.pilon"

    if (params.verbose){
        println ("[MODULE] pilon command: " + pilon_command)
    }

    //SHELL
    """
    ${pilon_command}
    """
}
