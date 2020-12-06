
input_ch = Channel.fromPath("${params.inputFolder}/*.bam")
referenceFasta = file("${params.referenceFasta}")

process samtoolsAddMD {
    container 'jweinstk/samtools:latest'
    containerOptions = "--user root"

    input:
    file bam from input_ch
    file referenceFasta

    output: 
    tuple env(outfilename), file("*.MD.bam") into samtoolsOut_ch

    """
    #!/bin/bash
    # logging
    ls -lah


    base=`basename ${bam} .bam | cut -d . -f1`
    outfilename="\$base"".opossum.bam"

    samtools calmd -@ ${task.cpus} -bAr ${bam} ${referenceFasta} > \$outfilename.MD.bam
    """
}




process runOpossum {
    container 'quay.io/vpeddu/u2af1-allele-bias:latest'
    containerOptions = "--user root"
    publishDir "${params.outdir}" //, mode: 'symlink'
    //cpus 1
    //memory 16.GB
    input:
    tuple val(base), file(bam) from samtoolsOut_ch

    output: 
    file "*.opossum.bam"

    """
    #!/bin/bash
    # logging
    ls -lah

    outfilename="${base}"".opossum.bam"
    echo "output file name is \$outfilename"
    
    # not sure why this is even necessary but fixed the file not found error
    touch \$outfilename

    python2.7 /Opossum-master/Opossum.py --BamFile=${bam} --OutFile="\$outfilename"
    """
}

