args <- commandArgs(trailingOnly = TRUE)
emission_file_one <- args[[1]]
emission_file_two <- args[[2]]
output_file <- args[[3]]

rename_state_column <- function(emissions_table) {
  return(dplyr::rename(emissions_table, State = "State (Emission order)"))
}

match_columns <- function(table_one, table_two) {
  table_one_column_order <- colnames(table_one)
  table_two <- dplyr::select(table_two, dplyr::all_of(table_one_column_order))
  return(list(table_one, table_two))
}

main <- function(emission_file_one, emission_file_two, output_file) {
  emissions_one <- data.table::fread(emission_file_one)
  emissions_two <- data.table::fread(emission_file_two)

  emissions_one <- rename_state_column(emissions_one)
  emissions_two <- rename_state_column(emissions_two)

  matched_emissions <- match_columns(emissions_one, emissions_two)
  emissions_one <- matched_emissions[[1]]
  emissions_two <- matched_emissions[[2]]

  emission_distances_matrix <-
    create_distances_matrix(
      emissions_one,
      emissions_two
    )

  save_file(emission_distances_matrix, output_file)
}
