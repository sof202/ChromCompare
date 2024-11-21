main <- function(matrix_file_path, output_file_path) {
  matrix <- read_matrix(matrix_file_path)
  heatmap <- generate_heatmap(matrix)
  save_heatmap(heatmap)
}

args <- commandArgs(trailingOnly = TRUE)
matrix_file_path <- args[[1]]
output_file_path <- args[[2]]

main(matrix_file_path, output_file_path)
