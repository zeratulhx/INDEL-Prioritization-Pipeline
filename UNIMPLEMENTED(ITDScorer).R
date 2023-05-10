#This determines the Levenshtein score for the data frame for each variant, when comparing the variant to the left and right sequence at the insertion point. This is a draft idea to ID duplications and is simplistic. 

# Determine the length of the alt sequence
df_split$alt_length <- nchar(df_split$V5)

# Skip variants where the alt sequence is too short (not interested in insertions less than 3 bases)
alt_length_threshold <- 3
df_split<- subset(df_split, df_split$alt_length >= alt_length_threshold)

# Convert the chromosome name to the RefSeq accession number
chrom_to_accession <- list(chr1 = "NC_000001.11", chr2 = "NC_000002.12", chr3 = "NC_000003.12", chr4 = "NC_000004.12", chr5 = "NC_000005.10", chr6= "NC_000006.12", chr7 = "NC_000007.14", chr8= "NC_000008.11", chr9= "NC_000009.12", chr10 = "NC_000010.11", chr11 = "NC_000011.10", chr12 = "NC_000012.12", chr13 = "NC_000013.11", chr14 = "NC_000014.9", chr15 = "NC_000015.10", chr16 = "NC_000016.10", chr17 = "NC_000017.11", chr18 = "NC_000018.10", chr19 = "NC_000019.10", chr20 = "NC_000020.11", chr21 = "NC_000021.9", chr22 = "NC_000022.11", chrX = "NC_000023.11",chrY = "NC_000024.10") 


df_split <- df_split[df_split$V1 %in% names(chrom_to_accession), ]
df_split$accession <- chrom_to_accession[match(df_split$V1, names(chrom_to_accession))]

# Define the start and end positions for the reference sequence
df_split$start <- as.integer(df_split$V2) - 1
df_split$end <- df_split$start + df_split$alt_length

# Use system() to retrieve the reference sequences
ref_fasta_path <- "/home/briana/shared/AdjacentSequence/ncbi-genomes-2023-04-08/GCF_000001405.40_GRCh38.p14_genomic.fna"
df_split$ref_fasta_cmd_right <- paste0("samtools faidx ", ref_fasta_path, " ", df_split$accession, ":", df_split$start+1, "-", df_split$end)
df_split$ref_seq_right <- sapply(df_split$ref_fasta_cmd_right, function(cmd) system(cmd, intern = TRUE)[2])
df_split$ref_fasta_cmd_left <- paste0("samtools faidx ", ref_fasta_path, " ", df_split$accession, ":", df_split$start-df_split$alt_length, "-", df_split$start-1)
df_split$ref_seq_left <- sapply(df_split$ref_fasta_cmd_left, function(cmd) system(cmd, intern = TRUE)[2])

# Compare the alt and reference sequences using Levenshtein distance
library(stringdist)
df_split$lev_distance_right <- stringdist(df_split$ref_seq_right, df_split$V5, method = "lv", nthread = 4)
df_split$lev_distance_left <- stringdist(df_split$ref_seq_left, df_split$V5, method = "lv", nthread = 4)


# Append the new information as a new column to the variant line
df_split$new_info_right <- ifelse(df_split$lev_distance_right != -1, paste0("Levenshtein=", df_split$lev_distance_right, "| Original sequence(right)=", df_split$ref_seq_right, ", Variant sequence=", df_split$V5), paste0("Levenshtein=", df_split$lev_distance_right, "|"))
df_split$new_info_left <- ifelse(df_split$lev_distance_left != -1, paste0("Levenshtein=", df_split$lev_distance_left, "| Original sequence(left)=", df_split$ref_seq_left, ", Variant sequence=", df_split$V5), paste0("Levenshtein=", df_split$lev_distance_left, "|"))


