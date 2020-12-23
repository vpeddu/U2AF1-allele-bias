library(Rsamtools)
library(ggplot2)
library(reshape2)

read_counts <- read.csv('/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/allele_bias/u2af1_ratios.csv', col.names = c('sample', 'U2AF1', 'newgene'))
melt(read_counts)

read_counts$ratio <- read_counts$newgene / read_counts$U2AF1


ggplot(read_counts, aes( x = factor(sample, level = level_order), y = ratio)) + 
  geom_histogram(stat = 'identity') + 
  theme_classic() + 
