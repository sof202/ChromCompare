main <- function(combined_assignments_file, bin_size, output_file_path) {
  combined_assignments <- data.table::fread(
    combined_assignments_file,
    colnames = c("model_one", "model_two")
  )
  model_one_stats_table <- data.table::data.table(
    "state" = numeric(1),
    "bp_in_assignment" = numeric(1),
  )
  model_two_stats_table <- data.table::data.table(
    "state" = numeric(1),
    "bp_in_assignment" = numeric(1),
  )
  model_one_stats_table <- model_one_stats_table |>
    fill_in_states(combined_assignments, 1) |>
    add_bp_coverage(combined_assignments, bin_size, 1)
  model_two_stats_table <- model_two_stats_table |>
    fill_in_states(combined_assignments, 2) |>
    add_bp_coverage(combined_assignments, bin_size, 2)
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
