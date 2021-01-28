library(fuzzyjoin)
library(Rsamtools)
library(ggplot2)
library(reshape2)
library(tidyr)
library(stringr)

setwd('/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/allele_bias')

metadata<-read.csv('/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/helpful_stuff/nf_rnaseq_input.csv')

read_counts <- read.csv('/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/u2af.csv', col.names = c('sample', 'U2AF1', 'U2AF1L5'))
melt(read_counts)

#total_read_counts <- read.csv('/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/r1read_counts.txt', sep = '\t', col.names = c('sample', 'total_count'))

metadata$sample<-paste0(metadata$group,'.',metadata$replicate)

combined<-merge(metadata, read_counts, by = 'sample')

combined$u2af1_RPM<- 1e6 * combined$U2AF1 / combined$total_reads
combined$u2af1l5_RPM<- 1e6 * combined$U2AF1L5 / combined$total_reads


#level_order = sort(me$sample)

graph_df<-melt(combined[c('sample','u2af1_RPM','u2af1l5_RPM')])

graph_df$replicate<-sapply(strsplit(as.character(graph_df$sample), "[.]"), "[[", 2)
graph_df$group<-sapply(strsplit(as.character(graph_df$sample), "[.]"), "[[", 1)

ggplot(graph_df, aes(x = group , y = value)) + 
  geom_jitter(height = 0, width = .2 ,aes(shape = variable, color = variable), size = 3) + 
  scale_y_continuous(limits = c(0, 15) )  + #, breaks = c(-1,0,20) )  + 
  theme_classic() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  ylab('RPM') + 
  xlab('Treament')
ggsave("u2af1_u2afl5_rpm_comparison.pdf", height = 5, width = 5)

ggplot(read_counts, aes( x = factor(sample, level = level_order), y = ratio)) + 
  geom_histogram(stat = 'identity') + 
  theme_classic() + 
  theme(axis.text.x = element_text(angle = 90))

for( i in unique(graph_df$group)){
  print(i)
print(wilcox.test(graph_df$value[graph_df$group == i & graph_df$variable == 'u2af1_RPM'],
            graph_df$value[graph_df$group == i & graph_df$variable == 'u2af1l5_RPM']))
}
