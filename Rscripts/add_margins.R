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

correct_invalid_bounds <- function(state_assignments, chromosome_sizes) {
  # When adding margins, some extremal intervals will end up being invalid.
  # For example, the intervals at the start of each chromosome will now span
  # into the negatives. We need to correct for such bounds.
  state_assignments <- dplyr::mutate(
    state_assignments,
    start = ifelse(start < 0, 0, start)
  )
  present_chromosomes <- unique(state_assignments[["chr"]])
  for (chromosome in present_chromosomes) {
    chromosome_size <- chromosome_sizes[[chromosome]]
    state_assignments <- dplyr::mutate(
      state_assignments,
      end = ifelse(
        end > chromosome_size,
        ifelse(chr == chromosome, chromosome_size, end),
        end
      )
    )
  }
  return(state_assignments)
}

save_file <- function(data, file_path) {
  data.table::fwrite(
    data,
    file = file_path,
    quote = FALSE,
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE
  )
}

main <- function(state_assignments_file,
                 margin,
                 chromosome_sizes_file,
                 output_file_path) {
  state_assignments <- data.table::fread(
    state_assignments_file,
    col.names = c("chr", "start", "end", "state")
  )
  chromosome_sizes <- process_chromosome_sizes(chromosome_sizes_file)
  state_assignments <- add_margins(state_assignments, margin)
  state_assignments <- correct_invalid_bounds(
    state_assignments,
    chromosome_sizes
  )
  save_file(state_assignments, output_file_path)
}

args <- commandArgs(trailingOnly = TRUE)
state_assignments_file <- args[[1]]
margin <- as.numeric(args[[2]])
chromosome_sizes_file <- args[[3]]
output_file_path <- args[[4]]

main(state_assignments_file, margin, chromosome_sizes_file, output_file_path)
