remove_state_column <- function(emissions_table) {
  return(dplyr::select(emissions_table, -"State (Emission order)"))
}

match_columns <- function(table_one, table_two) {
  table_one_column_order <- colnames(table_one)
  table_two <- dplyr::select(table_two, dplyr::all_of(table_one_column_order))
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

save_file <- function(matrix, file_path) {
  data.table::fwrite(
    matrix,
    file = file_path,
    quote = FALSE,
    row.names = TRUE,
    col.names = TRUE,
    sep = ","
  )
}

main <- function(emission_file_one, emission_file_two, output_file) {
  emissions_one <- data.table::fread(emission_file_one)
  emissions_two <- data.table::fread(emission_file_two)

  emissions_one <- remove_state_column(emissions_one)
  emissions_two <- remove_state_column(emissions_two)

  matched_emissions <- match_columns(emissions_one, emissions_two)
  emissions_one <- matched_emissions[[1]]
  emissions_two <- matched_emissions[[2]]

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

main(emission_file_one, emission_file_two, output_file_path)
