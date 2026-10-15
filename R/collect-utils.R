ao_check_integer <- function(x, name, minimum) {
  if (length(x) != 1 || !is.numeric(x) || is.na(x) || !is.finite(x) ||
      x < minimum || x != as.integer(x)) {
    stop(sprintf("`%s` must be an integer greater than or equal to %d.", name, minimum),
         call. = FALSE)
  }
  as.integer(x)
}

ao_check_nonnegative <- function(x, name) {
  if (length(x) != 1 || !is.numeric(x) || is.na(x) || !is.finite(x) || x < 0) {
    stop(sprintf("`%s` must be a non-negative number.", name), call. = FALSE)
  }
  invisible(x)
}

ao_batches <- function(x, size) {
  split(x, ceiling(seq_along(x) / size))
}

ao_deduplicate_matches <- function(matches) {
  key <- paste(matches$match_id, matches$profile_id, sep = "-")
  matches[!duplicated(key), , drop = FALSE]
}

ao_save_rds <- function(object, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(pattern = ".aoe2r-", tmpdir = dirname(file))
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary)
  if (!file.rename(temporary, file)) {
    stop(sprintf("Could not save '%s'.", file), call. = FALSE)
  }
}
