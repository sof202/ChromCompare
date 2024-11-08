main <- function(combined_assignments_file, bin_size, output_file_path) {
  stats_table <- data.table::data.table(
    "model_one_state" = numeric(1),
    "model_two_state" = numeric(2),
    "bp_in_model_one_state" = numeric(1),
    "bp_in_model_two_state" = numeric(1),
    "bp_in_overlap_for_state_pair" = numeric(1),
    "fold_enrichment_for_pair" = numeric(1)
  )
  genome_size <- calculate_genome_size(combined_assignments_file, bin_size)
  stats_table <- stats_table |>
    fill_in_states() |>
    calculate_bp_coverage(combined_assignments_file, bin_size, 1) |>
    calculate_bp_coverage(combined_assignments_file, bin_size, 2) |>
    calculate_overlapping_bp(combined_assignments_file, bin_size) |>
    calculate_fold_enrichment(genome_size)

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
