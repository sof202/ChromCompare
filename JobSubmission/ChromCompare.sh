#!/bin/bash
#SBATCH --export=ALL
#SBATCH -p mrcq 
#SBATCH --time=01:00:00
#SBATCH -A Research_Project-MRC190311 
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=16
#SBATCH --mem=8G
#SBATCH --mail-type=END 
#SBATCH --output=Compare%j.log
#SBATCH --error=Compare%j.err
#SBATCH --job-name=Compare


main() {
  config_file_location=$1
  check_config_file
  source_config_file "${config_file_location}"

  mkdir "${OUTPUT_DIRECTORY}/similarity_scores"

  emission_similarities_file="${PROCESSING_DIRECTORY}/similarity_scores/emission_similarity.txt"
  run_emission_similarity \
    "${MODEL_ONE_EMISSIONS_FILE}" \
    "${MODEL_TWO_EMISSIONS_FILE}" \
    "${emission_similarities_file}"

  margins=(0 "${BIN_SIZE}" $((BIN_SIZE * 10)))
  state_assignments_similarity_file="${PROCESSING_DIRECTORY}/similarity_scores/state_assignment_similarity.txt"
  run_spatial_similarity \
    "${MODEL_ONE_STATE_ASSIGNMENTS_FILE}" \
    "${MODEL_ONE_STATE_ASSIGNMENTS_FILE}" \
    "${state_assignments_similarity_file}" \
    "${margins[@]}"

  combined_similarity_score_file="${OUTPUT_DIRECTORY}/similarity_scores.txt"
  combine_similarity_scores \
    "${emission_similarities_file}" \
    "${state_assignments_similarity_file}" \
    "${combined_similarity_score_file}"

  if ! "${DEBUG_MODE}"; then clean_up; fi
}

if [[ $# -ne 1 ]]; then exit 1; fi
main "$1"
