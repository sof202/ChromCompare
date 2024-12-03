remove_state_column <- function(emissions_table) {
  return(dplyr::select(emissions_table, -"State (Emission order)"))
}

align_columns <- function(table_one, table_two) {
  common_marks <- intersect(colnames(table_one), colnames(table_two))
  if (length(colnames(table_two)) != length(colnames(table_one))) {
    message(
      "Marks between emission files do not align.",
      "We recommend using a smaller weight for this matrix."
    )
  }
  table_one <- dplyr::select(table_one, dplyr::all_of(common_marks))
  table_two <- dplyr::select(table_two, dplyr::all_of(common_marks))
  return(list(table_one, table_two))
}

create_distances_matrix <- function(emissions_one, emissions_two) {
  emissions_one <- as.matrix(emissions_one)
  emissions_two <- as.matrix(emissions_two)

  states_one <- seq_len(nrow(emissions_one))
  states_two <- seq_len(nrow(emissions_two))

  distances_matrix <- vapply(states_one, function(i) {
    vapply(states_two, function(j) {
      sqrt(sum((emissions_one[i, ] - emissions_two[j, ])^2))
    }, numeric(1))
  }, numeric(nrow(emissions_two)))

  colnames(distances_matrix) <- states_one
  rownames(distances_matrix) <- states_two

  return(distances_matrix)
}

main <- function(emission_file_one, emission_file_two, output_file) {
  emissions_one <- data.table::fread(emission_file_one)
  emissions_two <- data.table::fread(emission_file_two)

  emissions_one <- remove_state_column(emissions_one)
  emissions_two <- remove_state_column(emissions_two)

  aligned_emissions <- align_columns(emissions_one, emissions_two)
  emissions_one <- aligned_emissions[[1]]
  emissions_two <- aligned_emissions[[2]]

  emission_distances_matrix <-
    create_distances_matrix(
      emissions_one,
      emissions_two
    )

  save_file(emission_distances_matrix, output_file_path)
}

args <- commandArgs(trailingOnly = TRUE)
emission_file_one <- args[[1]]
emission_file_two <- args[[2]]
output_file_path <- args[[3]]

source("IO.R")
main(emission_file_one, emission_file_two, output_file_path)
