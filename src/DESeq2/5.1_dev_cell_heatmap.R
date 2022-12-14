invisible(lapply(list(
  "stringr",
  "tidyverse",
  "RColorBrewer",
  "factoextra",
  "ggplot2",
  "pheatmap"
), FUN = function(x) {
  suppressPackageStartupMessages(library(x, character.only = T))
}))

set.seed(snakemake@config[["seed"]])


# Read sample table and select relevant samples

samples <-
  read.table(
    # paste0(external_dir, "/iPS_ETVRUNX/dev_cell_samples.txt"),
    snakemake@input[["samples"]],
    header = TRUE,
    sep = "\t"
  )
samples <-
  subset.data.frame(samples, State == "hPSC D31" |
    State == "ETV6RUNX1 hIPS" |
    State == "Adult BM" |
    State == "Fetal Liver CS21-22" |
    State == "Fetal Liver CS17")
colnames(samples)[colnames(samples) == "proposed.sample.names"] <-
  "sample_name"

samples$State[grepl("Fetal Liver", samples$State)] <- "Fetal Liver"
samples$Cell_type[grepl("LIN-", samples$Cell_type)] <- "HSC-like"
samples$Cell_type[grepl("IL7R", samples$Cell_type)] <- "IL7R+"
samples <- samples[order(
  factor(samples$State, levels = c(
    "Adult BM", "Fetal Liver", "hPSC D31",
    "ETV6RUNX1 hIPS"
  )),
  factor(samples$Cell_type, levels = c(
    "HSC-like",
    "IL7R+",
    "ProB"
  ))
), ]

# Read fpkm table, select fetal signature genes and select samples from
# "samples" dataframe
geneexp <- read.table(
  snakemake@input[["fpkm"]],
  # paste0(external_dir, "/iPS_ETVRUNX/fpkm.tsv"),
  header = TRUE, sep = "\t"
)
# read.table("./DEseq2_analysis/Data/iPS_ETVRUNX/fpkm.tsv", header = TRUE, sep = "\t")

goi_fl <- read.table(
  file = snakemake@input[["deg"]],
  # file = paste0(out_dir, "/results/pseudorep_DE_genes.csv"),
  sep = ","
)
goi_fl <- goi_fl$FL_core_pos
goi_fl <- goi_fl[!is.na(goi_fl)]

geneexp <- geneexp[geneexp$X %in% goi_fl, ]
geneexp <- data.frame(geneexp, row.names = 1)
geneexp <- subset(geneexp, select = samples$sample_name)

# create dataframe for annotating heatmap according to sample groups

group <- paste(samples$State,
  samples$Cell_type,
  sep = "_"
)
group <- factor(group)


sample_groups <- data.frame(group)
sample_groups$sample_name <- samples$sample_name
row.names(sample_groups) <- sample_groups$sample_name
sample_groups$sample_name <- NULL
sample_groups$cell_type <- samples$Cell_type
sample_groups$sample_type <- samples$State
sample_groups$group <- NULL


# log transform, transpose and scale + center data

log_geneexp <- log2(geneexp + 1)
log_geneexp_transp <- data.frame(t(log_geneexp))

# scaled <- scale(log_geneexp_transp, center = TRUE, scale = FALSE) #for comparison
scaled_centered <- scale(log_geneexp_transp, center = TRUE, scale = TRUE)


# draw heatmap (transposed back to have to genes as rows and samples as columns)

annotation_colors <- list(
  "sample_type" = c(
    "Adult BM" = "#7A0E0E",
    "Fetal Liver" = "#08298A",
    "hPSC D31" = "#21610B",
    "ETV6RUNX1 hIPS" = "#4C0B5F"
  ), "cell_type" = c(
    "HSC-like" = "#D8D8D8",
    "IL7R+" = "#585858",
    "ProB" = "#151515"
  )
)

pheatmap((t(scaled_centered)),
  cluster_cols = FALSE,
  annotation_col = sample_groups,
  annotation_colors = annotation_colors,
  filename = snakemake@output[["plot_fig5"]]
  # filename = paste0(images_dir, "/Main_Figure_5a.pdf")
)

# pheatmap((t(scaled_centered)),
#          cluster_cols = TRUE,
#          annotation_col = sample_groups,
#          annotation_colors = annotation_colors,
# )
