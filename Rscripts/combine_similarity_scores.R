main <- function(emission_similarities_file,
                 spatial_similarities_file_list,
                 weights,
                 output_file_path) {
  emission_similarities <- read_matrix(emission_similarities_file)
  spatial_similarities <- lapply(
    spatial_similarities_file_list,
    function(file_path) {
      read_matrix(file_path)
    }
  )
  all_similarity_matrices <- append(
    emission_similarities,
    spatial_similarities
  )
  combined_matrix <- combine_similarity_matrices(
    all_similarity_matrices,
    weights
  )
  print_likely_state_pairs(combined_matrix)
  save_matrix(combined_matrix)
}

args <- commandArgs(trailingOnly = TRUE)
emission_similarities_file <- args[[1]]
spatial_similarities_file_list <- unlist(strsplit(args[[2]], ","))
weights <- as.numeric(unlist(strsplit(args[[3]], ",")))
output_file <- args[[4]]

main(
  emission_similarities_file,
  spatial_similarities_file_list,
  weights,
  output_file_path
)
