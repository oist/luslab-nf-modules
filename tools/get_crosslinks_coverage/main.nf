#!/usr/bin/env nextflow

// Specify DSL2
nextflow.enable.dsl=2

process get_crosslinks_coverage {
    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy", 
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }
    
    container 'luslab/nf-modules-get_crosslinks_coverage'

    input:
        val opts
        tuple val(meta), path(bed)

    output:
        tuple val(meta), path("${prefix1}.gz"), emit: bedGraph
        tuple val(meta), path("${prefix2}.gz"), emit: normBedGraph

    script:
        prefix1 = opts.suffix ? "${meta.sample_id}${opts.suffix}" : "${meta.sample_id}"
        prefix2 = opts.suffix ? "${meta.sample_id}.norm${opts.suffix}" : "${meta.sample_id}.norm"

        //SHELL
        """
        gunzip -c $bed | awk '{OFS = "\t"}{if (\$6 == "+") {print \$1, \$2, \$3, \$5} else {print \$1, \$2, \$3, -\$5}}' | pigz > ${prefix1}.gz
    
        TOTAL=`gunzip -c $bed | awk 'BEGIN {total=0} {total=total+\$5} END {print total}'`
        echo \$TOTAL
        gunzip -c $bed | awk -v total=\$TOTAL '{printf "%s\\t%i\\t%i\\t%s\\t%f\\t%s\\n", \$1, \$2, \$3, \$4, 1000000*\$5/total, \$6}' | \
        awk '{OFS = "\t"}{if (\$6 == "+") {print \$1, \$2, \$3, \$5} else {print \$1, \$2, \$3, -\$5}}' | \
        sort -k1,1 -k2,2n | pigz > ${prefix2}.gz
        """
}
