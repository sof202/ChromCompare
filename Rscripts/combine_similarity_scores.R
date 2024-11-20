read_matrix <- function(file_path) {
  matrix <- data.table::fread(
    file_path,
    sep = ",",
    header = TRUE
  )
  matrix <- as.matrix(matrix, rownames = seq_len(nrow(matrix)))
  return(matrix)
}

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


main <- function(emission_similarities_file,
                 spatial_similarities_file_list,
                 weights,
                 output_file_path) {
  emission_distances <- read_matrix(emission_similarities_file)
  spatial_similarities <- lapply(
    spatial_similarities_file_list,
    function(file_path) {
      read_matrix(file_path)
    }
  )
  max_fold_enrichment <- calculate_max_fold_enrichment(spatial_similarities)
  emission_similarities <- generate_emission_similarities(
    emission_distances,
    max_fold_enrichment
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
