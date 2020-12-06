
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
    tuple file("*.fai"), file("*.bai") into fileIndex_ch

    """
    #!/bin/bash
    # logging
    ls -lah


    base=`basename ${bam} .bam | cut -d . -f1`
    outfilename="\$base"".MD.bam"

    samtools calmd -@ ${task.cpus} -bAr ${bam} ${referenceFasta} > \$outfilename

    # needed for platypus to run  
    samtools index -@ ${task.cpus} \$outfilename \$outfilename.opossum.bam.bai
    """
}




process runOpossum {
    container 'quay.io/vpeddu/u2af1-allele-bias:latest'
    containerOptions = "--user root"
    publishDir "${params.outdir}/Opossum" //, mode: 'symlink'
    //cpus 1
    //memory 16.GB
    input:
    tuple val(base), file(bam) from samtoolsOut_ch

    output: 
    tuple val("${base}"), file("${base}.opossum.bam") into opossumOut_ch

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


process runPlatypus {
    container 'iarcbioinfo/platypus-nf'
    containerOptions = "--user root"
    publishDir "${params.outdir}/Platypus" //, mode: 'symlink'
    //cpus 1
    //memory 16.GB
    input:
    tuple val(base), file(bam) from opossumOut_ch
    file referenceFasta
    tuple file(fastaIndex), file(bamindex) from fileIndex_ch

    output: 
    file "${base}.platypus.vcf"

    """
    #!/bin/bash
    # logging
    ls -lah

    platypus callVariants \
        --bamFiles ${bam} \
        --refFile ${referenceFasta} \
        --filterDuplicates 0 \
        --minMapQual 0 \
        --minFlank 0 \
        --maxReadLength 500 \
        --minGoodQualBases 10 \
        --minBaseQual 20 \
        -o ${base}.platypus.vcf
    """
}

