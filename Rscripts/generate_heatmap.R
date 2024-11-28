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
  data[["model_one_state"]] <- as.numeric(data[["model_one_state"]])
  data[["model_two_state"]] <- as.numeric(data[["model_two_state"]])
  return(data)
}

generate_heatmap <- function(data, is_emission_matrix) {
  # Emission matrix should be flipped for interpretability. Lower values
  # means smaller distances which means higher similarity.
  if (is_emission_matrix) {
    low <- "red"
    high <- "white"
  } else {
    low <- "white"
    high <- "red"
  }
  heatmap <-
    ggplot(
      data,
      aes(x = model_one_state, y = model_two_state, fill = similarity_score)
    ) +
    geom_tile() +
    scale_fill_gradient(
      low = low,
      high = high,
      name = "Similarity score"
    ) +
    scale_x_continuous(breaks = unique(data[["model_one_state"]])) +
    scale_y_continuous(breaks = unique(data[["model_two_state"]])) +
    labs(
      x = "State from model one",
      y = "State from model two"
    ) +
    theme_bw()
  return(heatmap)
}

main <- function(matrix_file_path, output_file_path, is_emission_matrix) {
  matrix <- read_as_data_table(matrix_file_path)
  data <- reshape_data(matrix)
  heatmap <- generate_heatmap(data, is_emission_matrix)
  ggsave(
    output_file_path,
    heatmap,
    height = 10,
    width = 10
  )
}

library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)
matrix_file_path <- args[[1]]
output_file_path <- args[[2]]
is_emission_matrix <- args[[3]]

options(bitmapType = "cairo")
source("IO.R")
main(matrix_file_path, output_file_path, is_emission_matrix)
