#!/usr/bin/env Rscript

# Read in commandline arguments
args = commandArgs(trailingOnly=TRUE)

# Get path to the orthogroup gene count summary file
ogcounts <- args[1]
# And then the path to the samplesheet
samples <- args[2]

num_spp_filt <- as.numeric(args[3])
num_grp_filt <- as.numeric(args[4])
copy_num_filt1 <- as.numeric(args[5])
copy_num_filt2 <- as.numeric(args[6])

ogs <- read.delim(ogcounts)
samples <- read.delim(samples, sep = ",")

colnames(ogs) <- gsub("\\..*", "", colnames(ogs))

# Extract and remove the totals column
totals <- ogs['Total']
ogs <- ogs[,-which(colnames(ogs) == 'Total')]

# Convert zero-counts to NA
ogs[-1][ogs[-1] == 0] <- NA

# Calculate the mean copy number per species
copynum <- apply(ogs[-1], 1, mean, na.rm=T)

# Convert counts to a binary presence/absence
ogs[-1][ogs[-1] > 0] <- 1

# For each orthogroup, count the number of species included
numspp <- rowSums(ogs[-1], na.rm = T)

# Convert species names to taxon group
for(i in 2:ncol(ogs)){
    # Identify the species
    spp <- colnames(ogs)[i]

    # And the taxonomic group for this species
    grp <- unique(as.character(samples$taxonomy[which(samples$species == spp)]))

    # Now replace the species name with group name
    colnames(ogs)[i] <- grp
}

# Count number of taxonomic groups included in each orthogroup
taxcount <- t(rowsum(t(ogs[-1]),
              group = colnames(ogs)[-1],
              na.rm = T))
# Convert counts to binary for easy counts of species in each og.
taxcount[taxcount > 1] <- 1
taxcount <- rowSums(taxcount)

res <-
    data.frame(
        orthogroup = ogs$Orthogroup,
        num_spp = numspp,
        total_copy_num = totals,
        mean_copy_num = copynum,
        num_tax_grps = taxcount
    )

# Create the subsets
spptree_core <-
    res[which(res$mean_copy_num <= copy_num_filt1 &
              res$num_spp >= num_spp_filt &
              res$num_tax_grps >= num_grp_filt),]
genetree_core <-
    res[which(res$mean_copy_num <= copy_num_filt2 &
              res$num_spp >= num_spp_filt &
              res$num_tax_grps >= num_grp_filt),]

# And remove the species tree core ogs from the remnants we'll just infer gene
# family trees for (to eliminate redundant computational effort)
genetree_core <- genetree_core[-which(genetree_core$orthogroup %in% spptree_core$orthogroup),]

write.csv(res, paste0("all_ogs_counts.csv"), quote = F, row.names = F)
write.csv(spptree_core, paste0("spptree_core_ogs_counts.csv"), quote = F, row.names = F)
write.csv(genetree_core, paste0("genetree_core_ogs_counts.csv"), quote = F, row.names = F)
