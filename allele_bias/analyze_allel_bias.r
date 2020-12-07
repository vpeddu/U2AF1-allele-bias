library(vcfR)

args = commandArgs(trailingOnly=TRUE)

setwd("/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/allele_bias")

args = '/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/opossum/output'


vcf_files = list.files(args[1], pattern = "*.vcf", full.names = TRUE)

