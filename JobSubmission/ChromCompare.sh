#!/bin/bash
#SBATCH --export=ALL
#SBATCH -p mrcq 
#SBATCH --time=01:00:00
#SBATCH -A Research_Project-MRC190311 
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=16
#SBATCH --mem=8G
#SBATCH --mail-type=END 
#SBATCH --output=ChromCompare_%j.log
#SBATCH --error=ChromCompare_%j.err
#SBATCH --job-name=ChromCompare

check_config_file() {
  config_file_location=$1
  python \
    "${PYTHON_DIRECTORY}/check_config_file.py" \
    "${config_file_location}"
}


source_config_file() {
  config_file_location=$1
  source "${config_file_location}" | \
    { >&2 echo "Config file does not exist in specified location ($1)."
      exit 1; }
}


move_log_files() {
  log_directory="${OUTPUT_DIRECTORY}/LogFiles/${USER}"
  timestamp=$(date +%d-%h~%H-%M)
  mkdir -p "${log_directory}"
  mv "ChromCompare_${SLURM_JOB_ID}.log" \
    "${log_directory}/${timestamp}_${SLURM_JOB_ID}_ChromCompare.log"
  mv "ChromCompare_${SLURM_JOB_ID}.err" \
    "${log_directory}/${timestamp}_${SLURM_JOB_ID}_ChromCompare.err"
}


run_emission_similarity() {
  emission_file_one=$1
  emission_file_two=$2
  output_file=$3
  Rscript \
    "${RSCRIPT_DIRECTORY}/emission_similarity.R" \
    "${emission_file_one}" \
    "${emission_file_two}" \
    "${output_file}"
}

run_spatial_similarity() {
  state_assignment_file_one=$1
  state_assignment_file_two=$2
  emission_file_one=$3
  emission_file_two=$4
  output_file=$5

  shift 5
  margins=("$@")
  for margin in "${margins[@]}"; do
    Rscript \
      "${RSCRIPT_DIRECTORY}/spatial_similarity.R" \
      "${state_assignment_file_one}" \
      "${state_assignment_file_two}" \
      "${emission_file_one}" \
      "${emission_file_two}" \
      "${margin}" \
      "${output_file}"
  done
}

combine_similarity_scores() {
  emission_similarities_file=$1
  state_assignments_similarities_file=$2
  output_file=$3
  
  Rscript \
    "${RSCRIPT_DIRECTORY}/combine_similiarity_scores.R" \
    "${emission_similarities_file}" \
    "${state_assignments_similarities_file}" \
    "${output_file}"
}

main() {
  config_file_location=$1
  check_config_file "${config_file_location}"
  source_config_file "${config_file_location}"
  move_log_files

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
    "${MODEL_ONE_EMISSIONS_FILE}" \
    "${MODEL_TWO_EMISSIONS_FILE}" \
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
