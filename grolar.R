# Matthew Bashton 2017-2019
# Load JSON output from pizzly add in gene co-ordinates + compute distance when on same chr

# CRAN
#install.packages("jsonlite")
#install.packages("dplyr")

# Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install()
#BiocManager::install("ensembldb")
#BiocManager::install("EnsDb.Hsapiens.v86")

# Set up
# Change to your own output location
setwd("~/RNA_Seq")

# CRAN libs
library(jsonlite)
library(dplyr)

# Assuming you have used GRCh38 gene models
library(EnsDb.Hsapiens.v86)
edb <- EnsDb.Hsapiens.v86
listColumns(edb)
supportedFilters(edb)


# Suffix which apears after sample id in output file name
suffix <- "_fusion_GRCh38.json"

# Lets get a list of all the files we want to process
JSON_files <- list.files(path = getwd(), pattern = paste0("*",suffix))

# Make a list of Ids
Ids <- gsub(suffix, "", JSON_files)

# This function will flatten out the JSON giving you a list of gene A and gene
# B sorted by splitcount then paircount
GetFusionz <- function(sample, suffix) {

  # To test
  #sample <- Ids[1]
  #suffix = "_fusion_GRCh38.json"

  JSON_file <- paste0(sample, suffix)
  cat(paste("### Working on sample:", sample, "input file:", JSON_file, "###", "\n"))
  cat("Reading JSON..\n")
  JSON <- fromJSON(JSON_file, flatten = TRUE)
  cat("Extracting gene dataframe\n")
  JSON_level1 <- JSON$genes
  cat("Sorting by number of events\n")
  idx <- order(JSON_level1$splitcount, JSON_level1$paircount, decreasing = TRUE)
  output <- JSON_level1[idx,]
  # Clean up IDs
  output$geneA.id <- gsub(".\\d+$", "", output$geneA.id, perl = TRUE)
  output$geneB.id <- gsub(".\\d+$", "", output$geneB.id, perl = TRUE)
  cat(paste0("Writing out table: ", sample, "_fusions_filt_sorted.txt", "\n"))
  write.table(output[,c(-3,-4)], file = paste0(sample, "_fusions_filt_sorted.txt"), quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)
  cat("\n")
  return(TRUE)
}

# Use above funciton on all output files
#lapply(Ids, function(x) GetFusionz(x, suffix = "_fusion_GRCh38.json") )

# This function will flatten out the JSON giving you a list of gene A and gene B
# sorted by splitcount then paircount, it will also get co-ordinates for each
# gene, and if on same chr caculate distance between the two
GetFusionz_and_namez <- function(sample, suffix) {

  # To test
  #sample <- Ids[7]
  #suffix = "_fusion_GRCh38.json"

  JSON_file <- paste0(sample, suffix)
  cat(paste("### Working on sample:", sample, "input file:", JSON_file, "###", "\n"))
  cat("Reading JSON..\n")
  JSON <- fromJSON(JSON_file, flatten = TRUE)
  cat("Extracting gene dataframe\n")
  JSON_level1 <- JSON$genes
  output <- JSON_level1

  # Drop weird cols
  output <- output[,c(-3,-4)]

  # Clean up IDs
  output$geneA.id <- gsub(".\\d+$", "", output$geneA.id, perl = TRUE)
  output$geneB.id <- gsub(".\\d+$", "", output$geneB.id, perl = TRUE)

  # Add uniq-key
  output <- cbind(rownames(output), output)
  tmp <- colnames(output)[-1]
  colnames(output) <- c("ID", tmp)
  #colnames(output)
  #head(output)

  # Now extract geneA geneB locations
  # get all geneAs
  cat("Getting co-ordinates for gene A\n")
  geneAs <- output$geneA.id
  geneAs_info <- genes(edb,
        columns = c("gene_id","seq_name","gene_seq_start","gene_seq_end","seq_strand"),
        filter = GeneIdFilter(geneAs),
        return.type = "DataFrame")

  # get all geneBs
  cat("Getting co-ordinates for gene B\n")
  geneBs <- output$geneB.id
  geneBs_info <- genes(edb,
                       columns = c("gene_id","seq_name","gene_seq_start","gene_seq_end","seq_strand"),
                       filter = GeneIdFilter(geneBs),
                       return.type = "DataFrame")

  # Rename cols
  colnames(geneAs_info) <- paste0("geneA.", colnames(geneAs_info))
  colnames(geneBs_info) <- paste0("geneB.", colnames(geneBs_info))
  #colnames(geneAs_info)
  #colnames(geneBs_info)

  # Merge in geneA_info
  cat("Merging DFs\n")
  tmp1 <- merge(output, geneAs_info, by.x = "geneA.id", by.y = "geneA.gene_id", all.x = TRUE)
  tmp2 <- merge(output, geneBs_info, by.x = "geneB.id", by.y = "geneB.gene_id", all.x = TRUE)

  # Check we have the same length
  stopifnot(nrow(tmp1) == nrow(tmp2))

  # Merge these DFs
  output <- merge(tmp1, tmp2[,c(2,8:11)], by = "ID")[,c(1,3,4,2,5,8,9,10,11,6,7,12,13,14,15)]
  colnames(output)

  # Now use mutate
  cat("Finding genes on same chr\n")
  super_identical <- Vectorize(identical, c("x", "y"))
  # Need to convert from DataFrame to data.frame
  output <- as.data.frame(output)
  output <- mutate(output, same_chr = super_identical(output$geneA.seq_name,output$geneB.seq_name))
  identical_idx <- which(output$same_chr == TRUE)


  # New function for getting distance
  GetDistance <- function(RowIdx, dat) {
    OurRow <- dat[RowIdx,]
    # If we have NA annotation return NA
    if(any(is.na(c(dat[RowIdx,]$geneA.seq_name, dat[RowIdx,]$geneB.seq_name)))) {
      return(NA)
    }
    # Test which starts 1st geneA or geneB
      geneA_1st <- ifelse(OurRow$geneA.gene_seq_end < OurRow$geneB.gene_seq_start, TRUE,FALSE)
    if(geneA_1st == TRUE) {
      return(OurRow$geneB.gene_seq_start - OurRow$geneA.gene_seq_end)
    } else if(geneA_1st == FALSE) {
      return(OurRow$geneA.gene_seq_start - OurRow$geneB.gene_seq_end)
    }
  }

  # Test
  #GetDistance(22, output)
  #GetDistance(476, output)
  #GetDistance(5916, output)

  # Only run if our index has at least one TRUE value
  if(sum(identical_idx)) {

    # Get distances
    cat("Computing gene distances\n")
    geneDistance <- sapply(identical_idx, function(x) GetDistance(x, output))
    output[identical_idx,"gene_distance"] <- geneDistance

  }

  # Sort by splitcount then paircount
  cat("Sorting by number of events\n")
  idx <- order(output$splitcount, output$paircount, decreasing = TRUE)
  output <- output[idx,]

  # Write out output
  cat(paste0("Writing out table: ", sample, "_fusions_filt_sorted.txt", "\n"))
  write.table(output, file = paste0(sample, "_fusions_filt_sorted.txt"), quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)
  cat("\n")
  return(TRUE)
}

# Use above funciton on all output files
lapply(Ids, function(x) GetFusionz_and_namez(x, suffix = "_fusion_GRCh38.json") )
