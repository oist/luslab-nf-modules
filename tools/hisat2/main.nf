#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process hisat2_build {
    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy", 
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container 'f10927148e38'

    input:
        val opts
        path genome

    output:
        path "hisat2_index", emit: genome_index

    script:

        //SHELL
        """
        mkdir hisat2_index
        hisat2-build ${genome} hisat2_index/index
        """
}

process hisat2_align {
    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy", 
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container 'f10927148e38'

    input:
        val opts
        tuple val(meta), path(reads)
        path genome_index
        path splice_sites

    output:
        tuple val(meta), path("*.sam"), emit: sam

    script:
        args = ""
        if(opts.args && opts.args != '') {
            ext_args = opts.args
            args += ext_args.trim()
        }

        prefix = opts.suffix ? "${meta.sample_id}${opts.suffix}" : "${meta.sample_id}"

        //SHELL
        readList = reads.collect{it.toString()}
        if (readList.size > 1){
            hisat2_align_command = "hisat2 -x ${genome_index}/index -p ${task.cpus} --known-splicesite-infile ${splice_sites} \
            --met-file ${prefix}.txt -1 ${reads[0]} -2 ${reads[1]} -S ${prefix}.sam ${opts.args}"
        } else {
            hisat2_align_command = "hisat2 -x ${genome_index}/index -p ${task.cpus} --known-splicesite-infile ${splice_sites} \
            --met-file ${prefix}.txt -U ${reads} -S ${prefix}.sam ${opts.args}"
        }

        if (params.verbose){
            println ("[MODULE] hisat2 command: " + hisat2_align_command)
        }

        //SHELL
        """
        ${hisat2_align_command}
        """
}