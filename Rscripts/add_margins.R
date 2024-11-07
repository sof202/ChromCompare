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

add_margins <- function(state_assignments, margin) {
  state_assignments <- state_assignments |>
    dplyr::mutate(start = start - margin, end = end + margin)
}

main <- function(state_assignments_file, margin, chromosome_sizes_file) {
  state_assignments <- data.table::fread(
    state_assignments_file,
    col.names = c("chr", "start", "end", "state")
  )
  chromosome_sizes <- process_chromosome_sizes(chromosome_sizes_file)
  state_assignments <- add_margins(state_assignments, margin)
  save_file(state_assignments)
}

args <- commandArgs(trailingOnly = TRUE)
state_assignments_file <- args[[1]]
margin <- as.numeric(args[[2]])
chromosome_sizes_file <- args[[3]]

main(state_assignments_file, margin, chromosome_sizes_file)
