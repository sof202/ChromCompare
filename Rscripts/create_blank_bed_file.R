process_chromosome_sizes <- function(chromosome_sizes_file) {
  chromosome_sizes_table <- data.table::fread(
    chromosome_sizes_file,
    col.names = c("chromosome", "chromosome_size"),
    colClasses = c("character", "integer")
  )

  chromosome_sizes <- chromosome_sizes_table[["chromosome_size"]]
  names(chromosome_sizes) <- chromosome_sizes_table[["chromosome"]]
  return(chromosome_sizes)
}


create_bins <- function(chromosome_name, chromosome_length, bin_size) {
  if (!startsWith(chromosome_name, "chr")) {
    stop("chromosome name must start with the string 'chr'")
  }
  bin_starts <- seq(0, chromosome_length, bin_size)
  bins <- data.table::data.table("start" = bin_starts)
  bins <- bins |>
    dplyr::mutate(
      "chr" = chromosome_name,
      "end" = start + bin_size
    ) |>
    dplyr::select(chr, start, end)
  return(bins)
}

main <- function(bin_size,
                 state_assignments_file,
                 chromosome_sizes_file,
                 output_file_path) {
  chromosome_sizes <- process_chromosome_sizes(chromosome_sizes_file)
  state_assignments <- data.table::fread(
    state_assignments_file,
    col.names = c("chr", "start", "end", "state")
  )
  chromosome_names <- unique(state_assignments[["chr"]])

  blank_bed_data_list <- lapply(chromosome_names, function(chromosome_name) {
    chromosome_length <- chromosome_sizes[chromosome_name]
    do.call(create_bins, c(list(
      chromosome_name,
      chromosome_length,
      bin_size
    )))
  })

  blank_bed_data <- dplyr::bind_rows(blank_bed_data_list)
  print(head(blank_bed_data, 502))
  save_file(blank_bed_data, output_file_path, header = FALSE, sep = "\t")
}

args <- commandArgs(trailingOnly = TRUE)
bin_size <- as.numeric(args[[1]])
state_assignments_file <- args[[2]]
chromosome_sizes_file <- args[[3]]
output_file_path <- args[[4]]

# R converts positions that are multiples of 100000 to scientific notation.
# This behaviour causes bedtools to crash so we prevent this behaviour from
# ocurring.
options(scipen = 12)
source("IO.R")
main(bin_size, state_assignments_file, chromosome_sizes_file, output_file_path)
