process_state_assignments <- function(file) {
  state_assignments <- data.table::fread(
    state_assignments_one_file,
    col.names = c("chr", "start", "end", "state")
  ) |>
    dplyr::mutate("size" = end - start) |>
    dplyr::select(state, size)
  return(state_assignments)
}

find_states_assigned <- function(state_assignments) {
  states_present <- unique(state_assignments)
  sorted_states <- sort(states_present)
  return(sorted_states)
}

add_bp_coverage <- function(states, state_assignments) {
  bp_coverage <- lapply(states, function(state_number) {
    dplyr::filter(state_assignments, state == state_number) |>
      dplyr::select(size) |>
      sum()
  })
  stats_table <- data.table::data.table(
    "states" = states,
    "bp_coverage" = bp_coverage
  )
  return(stats_table)
}

merge_stats_tables <- function(stats_table_one, stats_table_two) {
  merged_stats_table <- data.table::data.table(
    "state_one" = integer(0),
    "state_two" = integer(0),
    "bp_coverage_one" = integer(0),
    "bp_coverage_two" = integer(0)
  )
  for (i in seq_len(nrow(stats_table_one))) {
    for (j in seq_len(nrow(stats_table_two))) {
      new_row <- c(
        "state_one" = stats_table_one[["states"]][[i]],
        "state_two" = stats_table_two[["states"]][[j]],
        "bp_coverage_one" = stats_table_one[["bp_coverage"]][[i]],
        "bp_coverage_two" = stats_table_two[["bp_coverage"]][[j]]
      )
      merged_stats_table <- dplyr::bind_rows(merged_stats_table, new_row)
    }
  }
  return(merged_stats_table)
}

add_bp_overlap <- function(stats_table, combined_assignments) {
  stats_table <- stats_table |>
    dplyr::left_join(
      combined_assignments,
      by = c("state_one" = "model_one", "state_two" = "model_two")
    ) |>
    dplyr::group_by(state_one, state_two) |>
    dplyr::summarise(
      bp_overlap = sum(overlap, na.rm = TRUE),
      .groups = "drop"
    ) |>
    data.table::as.data.table() |>
    dplyr::left_join(
      stats_table,
      by = c("state_one" = "state_one", "state_two" = "state_two")
    )
  return(stats_table)
}

calculate_genome_size <- function(combined_assignments, bin_size) {
  return(nrow(combined_assignments) * bin_size)
}

calculate_fold_enrichment <- function(a, b, c, d) {
  # Formula taken straight from OverlapEnrichment function from ChromHMM.
  # The manual for this function reads:
  #
  # By default the fold enrichment calculation is as follows, let:
  # A - be the number of bases in the state
  # B - be the number of bases in the external annotation
  # C - be the number of bases in the state and the external annotation
  # D - be the number of bases in the genome
  # The fold enrichment is then defined as (C/A)/(B/D).
  return((c * d) / (a * b))
}

add_fold_enrichment <- function(stats_table, genome_size) {
  stats_table <- dplyr::mutate(
    stats_table,
    "fold_enrichment" = calculate_fold_enrichment(
      bp_coverage_one,
      bp_coverage_two,
      bp_overlap,
      genome_size
    )
  )
  return(stats_table)
}

create_fold_enrichment_matrix <- function(stats_table) {
  fold_enrichment_matrix <- stats_table |>
    dplyr::select(state_one, state_two, fold_enrichment) |>
    tidyr::pivot_wider(
      names_from = state_one,
      values_from = fold_enrichment
    ) |>
    dplyr::select(-state_two) |>
    as.matrix()
  return(fold_enrichment_matrix)
}

main <- function(combined_assignments_file,
                 state_assignments_one_file,
                 state_assignments_two_file,
                 bin_size,
                 output_file_path) {
  state_assignments_one <- process_state_assignments(state_assignments_one_file)
  state_assignments_two <- process_state_assignments(state_assignments_two_file)
  model_one_stats_table <-
    find_states_assigned(state_assignments_one[["state"]]) |>
    add_bp_coverage(state_assignments_one)
  model_two_stats_table <-
    find_states_assigned(state_assignments_two[["state"]]) |>
    add_bp_coverage(state_assignments_two)
  stats_table <- merge_stats_tables(
    model_one_stats_table,
    model_two_stats_table
  )

  genome_size <- calculate_genome_size(state_assignments_one, bin_size)

  combined_assignments <- data.table::fread(
    combined_assignments_file,
    col.names = c("model_one", "model_two", "overlap")
  )
  stats_table <- stats_table |>
    add_bp_overlap(combined_assignments) |>
    add_fold_enrichment(genome_size)

  fold_enrichment_matrix <- create_fold_enrichment_matrix(stats_table)

  save_file(fold_enrichment_matrix, output_file_path)
}

args <- commandArgs(trailingOnly = TRUE)
combined_assignments_file <- args[[1]]
state_assignments_one_file <- args[[2]]
state_assignments_two_file <- args[[3]]
bin_size <- as.numeric(args[[4]])
output_file_path <- args[[5]]

source("IO.R")
main(
  combined_assignments_file,
  state_assignments_one_file,
  state_assignments_two_file,
  bin_size,
  output_file_path
)
