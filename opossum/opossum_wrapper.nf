input_ch = Channel.fromPath(params.inputFolder)

process runOpossum {
    container 'quay.io/vpeddu/u2af1-allele-bias:latest'
    publishDir "${params.OUTDIR}", mode: 'symlink'

    input:
    file BAM from input_ch

    output:
    file "top_hits.txt" into top_hits_ch

    """
    basename=`echo ${BAM} | cut -d . -f1`
    echo \$basename
    """
}

python Platypus.py --callVariants --bamFiles input.bam --refFile ref.fasta --filterDuplicates 0 --minMapQual 0 --minFlank 0 --maxReadLength 500 --minGoodQualBases 10 --minBaseQual 20 -o variants.vcf
