
//input_ch = Channel.fromPath("${params.inputFolder}/*.bam")
referenceFasta = file("${params.referenceFasta}") 
hisat2_ch = Channel
        .fromPath("${params.hisat2RefLocation}/*")
        .map{it -> file(it)}
        .collect()

//hisat2_ch.view()

//hisat2_ch = file("${params.hiSat2Index}/*.ht2")
input_read_ch = Channel
    .fromFilePairs("${params.inputFolder}*_R{1,2}*.gz")
    .ifEmpty { error "Cannot find any FASTQ pairs in ${params.INPUT} ending with .gz" }
    .map { it -> [it[0], it[1][0], it[1][1]]}

//input_read_ch.view()


process trimGalore{ 
    container 'dceoy/trim_galore:latest'
    containerOptions = "--user root"
    publishDir("${params.output}/trimGalore")

    cpus 4
    memory: 

    input:
    tuple val(base), file(R1), file(R2) from input_read_ch

    output: 
    tuple val("${base}"), file("${base}.trimmed_val_1.fq.gz"), file("${base}.trimmed_val_2.fq.gz") into trimOut_ch
    """
    #!/bin/bash

    echo "trimming ${base}"

    echo "logging ls"
    ls -lahtr

    trim_galore --fastqc --basename ${base}.trimmed --gzip -j ${task.cpus}  --paired ${R1} ${R2}
    """
}

process hiSat2{ 
    container 'nanozoo/hisat2:2.1.0--66dae66'
    containerOptions = "--user root"
    publishDir("${params.output}/hisat2")

    cpus 4
    memory: 

    input:
    tuple val(base), file(R1), file(R2) from trimOut_ch
    file "*" from hisat2_ch
    file referenceFasta
    output: 
    tuple val("${base}"), file("${base}.sorted.bam"), file("${base}.sorted.bam.bai") into hiSat2Out_ch
    file "*.fai" into fastaIndex_ch
    """
    #!/bin/bash

    echo "aligning ${base}"

    echo "logging ls"
    ls -lahtr

    hisat2 -p `expr ${task.cpus} - 2` --summary-file --met-stderr -x ${params.hisat2IndexPrefix} -1 ${R1} -2 ${R2} | samtools sort -@ 2 -O BAM - > ${base}.sorted.bam
    samtools index ${base}.sorted.bam

    samtools faidx ${referenceFasta}
    """
}




process runOpossum {
    container 'quay.io/vpeddu/u2af1-allele-bias:latest'
    containerOptions = "--user root"
    publishDir "${params.output}/Opossum" //, mode: 'symlink'
    //cpus 1
    //memory 16.GB
    input:
    tuple val(base), file(bam),file(bamIndex) from hiSat2Out_ch
    file index from fastaIndex_ch
    file referenceFasta
    //tuple val(base), file(bam) from samtoolsOut_ch

    output: 
    tuple val("${base}"), file("${base}.opossum.bam")  into opossumOut_ch
    file "${index}" into opossumFastaIndex_ch

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


process samtoolsAddMD {
    container 'jweinstk/samtools:latest'
    containerOptions = "--user root"

    input:
    tuple val(base), file(bam)  from opossumOut_ch

    output: 
    //tuple env(outfilename), file("*.MD.bam"), file("*.fai"), file("*.bai") into samtoolsOut_ch
    tuple val("${base}"), file ("${bam}"), file("${base}.opossum.bam.bai")  into fileIndex_ch

    """
    #!/bin/bash
    # logging
    ls -lah

    touch ${base}.opposum.bam.bai

    # needed for platypus to run  
    samtools index -@ ${task.cpus} ${bam} ${base}.opossum.bam.bai
    """
}

process runPlatypus {
    container 'iarcbioinfo/platypus-nf'
    containerOptions = "--user root"
    publishDir "${params.output}/Platypus" , mode: 'copy', overwrite: true
    //cpus 1
    //memory 16.GB
    input:
    tuple val(base), file(bam), file(bamIndex) from fileIndex_ch
    //tuple val(base), file(bam) from opossumOut_ch.groupTuple().join(fileIndex_ch )
    //tuple val(base) file(fastaIndex), file(bamindex) from fileIndex_ch
    file index from opossumFastaIndex_ch
    file referenceFasta
 
    output: 
    file "${base}.platypus.vcf" 
    file "${bamIndex}"
    file "${bam}"

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

