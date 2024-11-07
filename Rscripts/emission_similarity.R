args <- commandArgs(trailingOnly = TRUE)
emission_file_one <- args[[1]]
emission_file_two <- args[[2]]
output_file <- args[[3]]


main <- function(emission_file_one, emission_file_two, output_file) {
  emissions_one <- data.table::fread(emission_file_one)
  emissions_two <- data.table::fread(emission_file_two)

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
