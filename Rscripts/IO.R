read_as_matrix <- function(file_path) {
  matrix <- data.table::fread(
    file_path,
    sep = ",",
    header = TRUE
  )
  matrix <- as.matrix(matrix, rownames = seq_len(nrow(matrix)))
  return(matrix)
}

read_as_data_table <- function(file_path) {
  data <- data.table::fread(
    file_path,
    sep = ",",
    header = TRUE
  )
  return(data)
}

save_file <- function(data, file_path, header = TRUE, sep = ",") {
  write.table(
    data,
    file = file_path,
    sep = sep,
    col.names = header,
    row.names = FALSE,
    quote = FALSE
  )
}
