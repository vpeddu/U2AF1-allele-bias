import sys
import pysam 

filepath = '/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/test_bams/wgEncodeUwRepliSeqBg02esG2AlnRep1.R1.bam'

bamfile = pysam.AlignmentFile(filepath, "rb")