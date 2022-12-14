process ORTHOFINDER_MCL {
    tag "MCL clustering"
    // label 'process_highthread'
    label 'process_medium'
    container "${ workflow.containerEngine == 'docker' ? 'austinhpatton123/orthofinder-2.5.4_r-4.2.2' :
        '' }"

    input:
    each mcl_inflation
    path(blast)
    path(fasta)
    path(db)
    path(sppIDs)
    path(seqIDs)
    val output_directory

    output:
    path("*/Results_Inflation*"), emit: inflation_dir

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def inflation_param = mcl_inflation ? "${mcl_inflation}" : '1.5'

    """
    for f in \$(ls TestBlast*)
    do
        mv \$f \$(echo \$f | sed "s/TestBlast/Blast/g")
    done

    orthofinder \\
        -b ./ \\
        -n "Inflation_${inflation_param}" \\
        -I $inflation_param \\
        -M msa -X -os -z \\
        -a ${task.cpus} \\
        $args

    # Restructure to get rid of the unnecessary "OrthoFinder" directory"
    mv OrthoFinder ${output_directory}
    """
}
