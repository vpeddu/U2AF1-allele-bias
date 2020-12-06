
input_ch = Channel.fromPath("${params.inputFolder}/*.bam")

process runOpossum {
    container 'quay.io/vpeddu/u2af1-allele-bias:latest'
    //publishDir "${params.OUTDIR}", mode: 'symlink'

    input:
    file BAM from input_ch

    output: 
    //file "\$base.bam"
    //file "top_hits.txt" into top_hits_ch

    """
    #!/bin/bash
    # logging
    ls -lah


    base=`basename ${BAM} .bam | cut -d . -f1`
    outfilename="\$base""opossum.bam"
    echo \$outfilename
    python2.7 /Opossum-master/Opossum.py --BamFile=${BAM} --OutFile="\$outfilename"
    """
}

//python Platypus.py --callVariants --bamFiles input.bam --refFile ref.fasta --filterDuplicates 0 --minMapQual 0 --minFlank 0 --maxReadLength 500 --minGoodQualBases 10 --minBaseQual 20 -o variants.vcf
