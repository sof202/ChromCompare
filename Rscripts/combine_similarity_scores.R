calculate_max_fold_enrichment <- function(spatial_similarities) {
  max_fold_enrichments <- vapply(
    spatial_similarities,
    max,
    numeric(1)
  )
  return(max(max_fold_enrichments))
}

calculate_emission_score <- function(distance,
                                     max_distance,
                                     max_fold_enrichment) {
  max_fold_enrichment * (1 - distance / max_distance)
}

generate_emission_similarities <- function(emission_similarities,
                                           max_fold_enrichment) {
  # The emissions matrix read in contains Euclidean distances. Here, a smaller
  # number signifies higher similarity. However, with the spatial
  # similarities, a higher fold enrichment signifies higher similarity. In
  # order to make these two types of similarity comparable, a basic scalar
  # transform is used. This ensures that low Euclidean distances are converted
  # to scores comparable to the highest spatial similarity scores, whilst high
  # Euclidean distances are converted to values close to zero.
  max_euclidean_distance <- max(emission_similarities)
  emission_similarity_scores <- apply(
    emission_similarities,
    c(1, 2),
    calculate_emission_score,
    max_euclidean_distance,
    max_fold_enrichment
  )
  return(emission_similarity_scores)
}

combine_similarity_matrices <- function(matrix_list, weights) {
  stopifnot(length(matrix_list) == length(weights))

  # Faster to do this than initialise matrix with proper size and names
  combined_matrix <- matrix_list[[1]] * 0
  for (i in seq_along(matrix_list)) {
    combined_matrix <- combined_matrix + weights[[i]] * matrix_list[[i]]
  }
  return(combined_matrix)
}

get_likely_state_pairs <- function(similarity_scores) {
  likely_state_pairs <- apply(
    similarity_scores,
    2,
    function(row) {
      which(similarity_scores == max(row), arr.ind = TRUE)
    }
  )

  # Makes the resultant matrix in a more readable fashion
  likely_state_pairs <- t(likely_state_pairs)[, c(2, 1)]
  colnames(likely_state_pairs) <- c("model_one_state", "model_two_state")

  return(likely_state_pairs)
}

main <- function(emission_similarities_file,
                 spatial_similarities_files,
                 weights,
                 output_file_path) {
  emission_distances <- read_as_matrix(emission_similarities_file)
  spatial_similarities <- lapply(
    spatial_similarities_files,
    function(file_path) {
      read_as_matrix(file_path)
    }
  )
  max_fold_enrichment <- calculate_max_fold_enrichment(spatial_similarities)
  emission_similarities <- generate_emission_similarities(
    emission_distances,
    max_fold_enrichment
  )
  all_similarity_matrices <- append(
    list(emission_similarities),
    spatial_similarities
  )
  combined_matrix <- combine_similarity_matrices(
    all_similarity_matrices,
    weights
  )
  likely_state_pairs <- get_likely_state_pairs(combined_matrix)
  save_file(
    likely_state_pairs,
    file.path(output_file_path, "likely_state_pairs.txt")
  )
  save_file(
    combined_matrix,
    file.path(output_file_path, "similarity_scores.txt")
  )
}

args <- commandArgs(trailingOnly = TRUE)
emission_similarities_file <- args[[1]]
spatial_similarities_files <- unlist(strsplit(args[[2]], ","))
weights <- as.numeric(unlist(strsplit(args[[3]], ",")))
output_file_path <- args[[4]]

source("IO.R")
main(
  emission_similarities_file,
  spatial_similarities_files,
  weights,
  output_file_path
)
