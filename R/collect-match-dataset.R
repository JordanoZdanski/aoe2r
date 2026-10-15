#' Collect a reproducible match dataset
#'
#' Selects players from one leaderboard, downloads their recent match history,
#' and returns one deduplicated row per player per match. When `path` is set,
#' checkpoints make an interrupted collection resumable.
#'
#' @param leaderboard_id Integer ladder id.
#' @param n_profiles Integer number of leaderboard players to collect.
#' @param start Integer first leaderboard rank.
#' @param path Directory for checkpoints, or `NULL` for an in-memory collection.
#' @param resume Whether to resume checkpoints already present in `path`.
#' @param pause Seconds to wait between history batches.
#'
#' @return A tibble with collection metadata in its `collection_metadata`
#'   attribute.
#' @export
collect_match_dataset <- function(leaderboard_id = 3, n_profiles = 200,
                                  start = 1, path = NULL, resume = TRUE,
                                  pause = 1) {
  leaderboard_id <- ao_check_integer(leaderboard_id, "leaderboard_id", 1)
  n_profiles <- ao_check_integer(n_profiles, "n_profiles", 1)
  start <- ao_check_integer(start, "start", 1)
  ao_check_nonnegative(pause, "pause")

  configuration <- list(leaderboard_id = leaderboard_id, n_profiles = n_profiles,
                        start = start)
  manifest_file <- if (is.null(path)) NULL else file.path(path, "manifest.rds")

  if (!is.null(manifest_file) && file.exists(manifest_file)) {
    if (!isTRUE(resume)) {
      stop("A collection already exists at `path`; use `resume = TRUE` or a new path.",
           call. = FALSE)
    }
    manifest <- readRDS(manifest_file)
    if (!identical(manifest$configuration, configuration)) {
      stop("The saved collection configuration does not match this request.", call. = FALSE)
    }
  } else {
    players <- get_leaderboard(leaderboard_id, start, n_profiles)
    if (nrow(players) < n_profiles) {
      stop("The leaderboard returned fewer players than requested.", call. = FALSE)
    }
    manifest <- list(configuration = configuration, profile_ids = players$profile_id,
                     started_at = Sys.time(), package_version = as.character(utils::packageVersion("aoe2r")))
    if (!is.null(manifest_file)) {
      ao_save_rds(manifest, manifest_file)
    }
  }

  batches <- ao_batches(manifest$profile_ids, 10L)
  results <- lapply(seq_along(batches), function(i) {
    checkpoint <- if (is.null(path)) NULL else file.path(path, "batches", sprintf("batch-%04d.rds", i))
    if (!is.null(checkpoint) && file.exists(checkpoint)) {
      return(readRDS(checkpoint))
    }
    message(sprintf("Collecting batch %d of %d.", i, length(batches)))
    value <- get_player_matches(batches[[i]], pause = 0)
    if (!is.null(checkpoint)) {
      ao_save_rds(value, checkpoint)
    }
    if (i < length(batches) && pause > 0) {
      Sys.sleep(pause)
    }
    value
  })

  matches <- ao_deduplicate_matches(tibble::as_tibble(do.call(rbind, results)))
  metadata <- c(manifest, list(completed_at = Sys.time(), batches = length(batches),
                               rows = nrow(matches), unique_matches = length(unique(matches$match_id))))
  attr(matches, "collection_metadata") <- metadata
  class(matches) <- c("aoe2r_match_dataset", class(matches))
  matches
}
