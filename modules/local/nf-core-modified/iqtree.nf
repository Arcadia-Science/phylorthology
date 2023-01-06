process IQTREE {
    tag "$alignment"
    //label 'process_highthread' // Possible specification for full analysis
    label 'process_medium' // Used for debugging

    conda (params.enable_conda ? 'bioconda::iqtree=2.1.4_beta' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.1.4_beta--hdcc8f71_0' :
        'quay.io/biocontainers/iqtree:2.1.4_beta--hdcc8f71_0' }"

    input:
    tuple path(alignment)
    val model
    val pmsf_model

    output:
    path("*.treefile")                  , emit: phylogeny
    path "*.log"                        , emit: iqtree_log
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def memory      = task.memory.toString().replaceAll(' ', '')

    """
    memory=\$(echo ${task.memory} | sed "s/.G/G/g")

    # Check if this is a resumed run:
    # error trying to resume if not.)
    # If the checkpoint file indicates the run finished, go ahead and
    # skip the analyses, otherwise run iqtree as normal.

    # Infer the guide tree for PMSF approximation
    iqtree \\
        -s $alignment \\
        -nt AUTO \\
        -ntmax ${task.cpus} \\
        -mem \$memory \\
        -m $model \\
        $args

    # check if we're running a PMSF approximation - if so, do the following,
    # treating the tree inferred above as a guide tree
    if [ "$pmsf_model" != "none" ]; then
        # Identify the best number of threads
        nt=\$(grep "BEST NUMBER" *.log | sed "s/.*: //g")
    
        # Rename it and clean up
        mv *.treefile guidetree.treefile
        rm *fa.*
    
        iqtree \\
            -s $alignment \\
            -nt \$nt \\
            -mem \$memory \\
            -m $pmsf_model \\
            -ft guidetree.treefile \\
            $args
            
        # Clean up
        rm ./guidetree.treefile
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """
}
