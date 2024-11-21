read_matrix <- function(file_path) {
  matrix <- data.table::fread(
    file_path,
    sep = ",",
    header = TRUE
  )
  return(matrix)
}

reshape_data <- function(data) {
  # Data needs to be reshaped in order to be in the form that will work with
  # ggplot
  data <- dplyr::mutate(data, "model_two_state" = rownames(data), .before = 1)
  data <- tidyr::pivot_longer(
    data,
    cols = -model_two_state,
    names_to = "model_one_state",
    values_to = "similarity_score"
  )
  return(data)
}

main <- function(matrix_file_path, output_file_path) {
  matrix <- read_matrix(matrix_file_path)
  data <- reshape_data(matrix)
  heatmap <- generate_heatmap(matrix)
  ggsave(
    output_file_path,
    heatmap
  )
}

library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)
matrix_file_path <- args[[1]]
output_file_path <- args[[2]]

options(bitmapType = "cairo")
main(matrix_file_path, output_file_path)
