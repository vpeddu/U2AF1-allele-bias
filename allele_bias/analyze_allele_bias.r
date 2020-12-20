library(vcfR)
library(VariantAnnotation)
library(TVTB)
library(svMisc)
library(ggplot2)


# read from command line
args = commandArgs(trailingOnly=TRUE)

setwd("/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/allele_bias")

# testing
args = '/Users/vikas/Documents/UCSC/rotations/Brooks/rotation_project/U2AF1-allele-bias/opossum/output'

#read in vcf files
vcf_files = list.files(args[1], pattern = "*.vcf", full.names = TRUE)

treatment<-c()
replicate<-c()
full_path<-c()
for( i in vcf_files){ 
  t = strsplit(basename(i),'_R')[[1]][1]
  r = strsplit(basename(i),'_R')[[1]][2]
  treatment<-append(treatment,t )
  replicate<-append(replicate, strsplit(r,'[.]')[[1]][1])
  full_path<-append(full_path,i)
  }

metadata_df<-data.frame(treatment,replicate,full_path)

analyze_vcf <- function(vcfpath){ 
  temp_vcf <- VariantAnnotation::readVcf(vcfpath)
   fixedRules <- VcfFixedRules(exprs = list(
     alleleBias = expression(FILTER == "alleleBias"),
     qual20 = expression(QUAL >= 20)
   ))
   active(fixedRules)["qual20"] <- FALSE
   validrecords <- summary(evalSeparately(fixedRules, temp_vcf))[1]
   allelebias<-summary(evalSeparately(fixedRules, temp_vcf))[2]
   
   return(c(validrecords, allelebias))
}


metadata_df$totalrecords<-NA
metadata_df$allelebiascount<-NA
for (i in 1:nrow(metadata_df)){
  progress(i)
  results<- analyze_vcf(metadata_df$full_path[i])
  metadata_df$totalrecords[i]<-results[1]
  metadata_df$allelebiascount[i]<-results[2]
}



sd_allelebias_df<-metadata_df[which(!duplicated(metadata_df$treatment)),]
sd_allelebias_df$replicate<-NULL
sd_allelebias_df$full_path<-NULL
sd_allelebias_df$median<-NA
sd_allelebias_df$q1<-NA
sd_allelebias_df$q3<-NA
for(i in  unique(metadata_df$treatment)){ 
  summary<-(summary(100 * (metadata_df$allelebiascount[metadata_df$treatment == i]) / metadata_df$totalrecords[metadata_df$treatment == i]))
  match<-which(sd_allelebias_df$treatment == i)
  sd_allelebias_df$median[match]<-summary[3]
  sd_allelebias_df$q1[match]<-summary[1]
  sd_allelebias_df$q3[match]<-summary[6]
  }

allelebiascountplot<-ggplot(sd_allelebias_df,aes(x = treatment, y = median, fill = treatment)) + 
  geom_bar(stat = 'identity') + 
  theme_minimal() + 
  geom_errorbar( aes(x=treatment, ymin=q1, ymax=q3)) +
  scale_y_continuous(limits = c(0,2)) + 
  ylab("% of total records marked as allele bias") +
  theme(axis.text.x = element_text(angle = 45, hjust=1, vjust = 1.2), legend.position = "none")

allelebiascountplot



