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

usage() {
cat << MESSAGE
============================================================================
$(basename "$0")
============================================================================
Purpose: Using emission and state assignment files from two models generated
from ChromHMM's LearnModel command, generates a matrix of similarity scores
between the states of each model.
Arguments: \$1 -> full/path/to/config/file
Author: Sam Fletcher
Contact: s.o.fletcher@exeter.ac.uk
============================================================================
MESSAGE
  exit 0
}

check_config_file() {
  config_file_location=$1
  script_location=$(\
    scontrol show job "${SLURM_JOB_ID}" | \
    grep "Command" | \
    awk '{print $1}' | \
    awk 'BEGIN {FS="="} {print $2}' \
  )
    cd "$(dirname "${script_location}")" || exit 1
    cd .. || exit 1
  python \
    "Python_Scripts/check_config_file.py" \
    "${config_file_location}"
  if [[ $? -eq 1 ]]; then
    echo "ERROR: malformed config file detected."
    exit 1
  fi
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

create_blank_bins() {
  state_assignment_file_one=$1
  output_file=$2

  Rscript \
    "${RSCRIPT_DIRECTORY}/create_blank_bed_file" \
    "${BIN_SIZE}" \
    "${state_assignment_file_one}" \
    "${CHROMOSOME_SIZES_FILE}" \
    "${PROCESSING_DIRECTORY}/blank_bins.bed"

  # Sorting required for later bedtools intersect. The output of the Rscript is
  # most likely sorted alphabetically rather than numerically (for chromosome
  # order)
  bedtools sort -i \
    "${PROCESSING_DIRECTORY}/blank_bins.bed" > \
    "${output_file}"

}

convert_state_assignments() {
  # ChromHMM's state assignment files are created in a way to be memory 
  # efficient. If multiple bins have the same state assignment, they are
  # collapsed into one. This is not ideal for this pipeline as we want to
  # count the number of base pairs assigned to each state pair. By converting
  # these files to no longer be collapsed, the code becomes more efficient and
  # easier to follow.
  sorted_blank_bins_file=$1
  state_assignment_file=$2
  output_file_path=$3

  bedtools intersect \
    -wb \
    -a "${sorted_blank_bins_file}" \
    -b "${state_assignment_file}" | \
    awk '{OFS = "\t"} {print $1,$2,$3,$7}' > \
    "${output_file_path}"
}

run_spatial_similarity() {
  state_assignment_file_one=$1
  state_assignment_file_two=$2
  output_file_prefix=$3

  for margin in "${MARGINS[@]}"; do
    Rscript \
      "${RSCRIPT_DIRECTORY}/add_margins.R" \
      "${state_assignment_file_one}" \
      "${margin}" \
      "${PROCESSING_DIRECTORY}/state_assignments_one_margin_${margin}.bed"

    Rscript \
      "${RSCRIPT_DIRECTORY}/add_margins.R" \
      "${state_assignment_file_two}" \
      "${margin}" \
      "${PROCESSING_DIRECTORY}/state_assignments_two_margin_${margin}.bed"

    bedtools intersect \
      -wo \
      -a "${PROCESSING_DIRECTORY}/state_assignments_one_margin_${margin}.bed" \
      -b "${PROCESSING_DIRECTORY}/state_assignments_two_margin_${margin}.bed" | \
      awk '{OFS="\t"} {print $4,$8,$9}' > \
      "${PROCESSING_DIRECTORY}/state_assignment_overlap_margin_${margin}.bed"


    Rscript \
      "${RSCRIPT_DIRECTORY}/spatial_similarity.R" \
      "${PROCESSING_DIRECTORY}/state_assignment_overlap_margin_${margin}.bed" \
      "${BIN_SIZE}" \
      "${PROCESSING_DIRECTORY}/${output_file_prefix}${margin}.txt"
  done
}

combine_similarity_scores() {
  emission_similarities_file=$1
  spatial_similarities_prefix=$2

  spatial_similarities_files=$( \
    find "${PROCESSING_DIRECTORY}" \
    -name "${spatial_similarities_prefix}*.txt" | \
    tr '\n' ',' | \
    sed 's/,$//'
  )
  
  Rscript \
    "${RSCRIPT_DIRECTORY}/combine_similiarity_scores.R" \
    "${emission_similarities_file}" \
    "${spatial_similarities_files}" \
    "${WEIGHTS}" \
    "${OUTPUT_DIRECTORY}"
}

clean_up() {
  printf "Removing files:"
  printf "%s\n" "$@"
  printf "To stop this behaviour, set \$DEBUG_MODE to 1."
  rm "$@"
}

main() {
  config_file_location=$1
  check_config_file "${config_file_location}"
  source_config_file "${config_file_location}"
  move_log_files

  mkdir -p \
    "${OUTPUT_DIRECTORY}" \
    "${PROCESSING_DIRECTORY}"

  emission_similarities_file="${PROCESSING_DIRECTORY}/emission_similarity.txt"
  run_emission_similarity \
    "${MODEL_ONE_EMISSIONS_FILE}" \
    "${MODEL_TWO_EMISSIONS_FILE}" \
    "${emission_similarities_file}"

  create_blank_bins \
    "${MODEL_ONE_STATE_ASSIGNMENTS_FILE}" \
    "${PROCESSING_DIRECTORY}/sorted_blank_bins.bed"

  convert_state_assignments \
    "${PROCESSING_DIRECTORY}/sorted_blank_bins.bed" \
    "${MODEL_ONE_STATE_ASSIGNMENTS_FILE}" \
    "${PROCESSING_DIRECTORY}/state_assignments_model_one.bed"
  convert_state_assignments \
    "${PROCESSING_DIRECTORY}/sorted_blank_bins.bed" \
    "${MODEL_TWO_STATE_ASSIGNMENTS_FILE}" \
    "${PROCESSING_DIRECTORY}/state_assignments_model_two.bed"

  state_assignments_similarity_file_prefix="${PROCESSING_DIRECTORY}/state_assignment_similarity_margin_"
  run_spatial_similarity \
    "${PROCESSING_DIRECTORY}/state_assignments_model_one.bed"
    "${PROCESSING_DIRECTORY}/state_assignments_model_two.bed"
    "${state_assignments_similarity_file_prefix}"

  combine_similarity_scores \
    "${emission_similarities_file}" \
    "${state_assignments_similarity_file_prefix}"

  if [[ "${DEBUG_MODE}" -eq 1 ]]; then
    clean_up \
      "${emission_similarities_file}"
  fi
}

if [[ $# -ne 1 ]]; then usage; fi
if [[ -z "${SLURM_JOB_ID}" ]]; then
  echo "You must run this script under SLURM using sbatch."
  exit 1
fi
main "$1"
