main <- function(state_assignments_file, margin) {
  state_assignments <- data.table::fread(state_assignments_file)
  state_assignments <- add_margins(state_assignments)
  save_file(state_assignments)
}

args <- commandArgs(trailingOnly = TRUE)
state_assignments_file <- args[[1]]
margin <- as.numeric(args[[2]])

main(state_assignments_file, margin)
