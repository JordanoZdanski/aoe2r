#' Save a collected match dataset
#'
#' Saves a dataset returned by [collect_match_dataset()] as an RDS file.
#'
#' @param dataset A dataset returned by [collect_match_dataset()].
#' @param file Output RDS file.
#' @param overwrite Whether to overwrite an existing file.
#'
#' @return `file`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' save_match_dataset(dataset, "dataset-rm.rds", overwrite = TRUE)
#' }
save_match_dataset <- function(dataset, file, overwrite = FALSE) {
  if (!inherits(dataset, "aoe2r_match_dataset")) {
    stop("`dataset` must come from `collect_match_dataset()`.", call. = FALSE)
  }
  if (length(file) != 1 || !is.character(file) || is.na(file) || !nzchar(file)) {
    stop("`file` must be one non-empty path.", call. = FALSE)
  }
  if (file.exists(file) && !isTRUE(overwrite)) {
    stop("`file` already exists; use `overwrite = TRUE` to replace it.", call. = FALSE)
  }
  ao_save_rds(dataset, file)
  invisible(file)
}
