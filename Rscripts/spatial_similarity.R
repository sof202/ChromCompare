find_states_assigned <- function(state_assignments) {
  states_present <- unique(state_assignments)
  sorted_states <- sort(states_present)
  return(sorted_states)
}

add_bp_coverage <- function(states, state_assignments, bin_size) {
  bp_coverage <- lapply(states, function(state) {
    sum(state_assignments == state) * bin_size
  })
  stats_table <- data.table::data.table(
    "states" = states,
    "bp_coverage" = bp_coverage
  )
  return(stats_table)
}

main <- function(combined_assignments_file, bin_size, output_file_path) {
  combined_assignments <- data.table::fread(
    combined_assignments_file,
    colnames = c("model_one", "model_two")
  )
  model_one_stats_table <-
    find_states_assigned(combined_assignments[["model_one"]]) |>
    add_bp_coverage(combined_assignments, bin_size)
  model_two_stats_table <-
    find_states_assigned(combined_assignments[["model_two"]]) |>
    add_bp_coverage(combined_assignments, bin_size)
  stats_table <- merge_stats_tables(
    model_one_stats_table,
    model_two_stats_table
  )
  colnames(stats_table) <- c(
    "state_one", "bp_in_assignment_one",
    "state_two", "bp_in_assignment_two"
  )

  stats_table <- add_bp_overlap(stats_table)

  genome_size <- calculate_genome_size(combined_assignments, bin_size)

  fold_enrichment_matrix <- create_fold_enrichment_matrix(stats_table)
  fold_enrichment_heatmap <-
    create_fold_enrichment_heatmap(fold_enrichment_matrix)

  save_matrix(fold_enrichment_matrix)
  save_heatmap(fold_enrichment_heatmap)
}

args <- commandArgs(trailingOnly = TRUE)
combined_assignments_file <- args[[1]]
bin_size <- as.numeric(args[[2]])
output_file_path <- args[[3]]

main(combined_assignments_file, bin_size, output_file_path)
