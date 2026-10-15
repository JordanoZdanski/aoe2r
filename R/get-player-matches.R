#' Match history for one or more players
#'
#' Returns completed matches as one row **per player**, not per match, so the
#' result feeds straight into tidymodels without `tidyr::unnest()`.
#'
#' Any number of players can be requested. The backend accepts ten `profile_id`
#' values per request, so larger inputs are split into batches automatically.
#'
#' Only finished matches appear. There is no endpoint for in-progress games.
#'
#' @param profile_id Integer Relic profile id (or a vector). Get
#'   one from [get_leaderboard()] or [get_player_profile()].
#' @param pause Seconds to wait between batches.
#'
#' @return A tibble with one row per player per match: `match_id`,
#'   `matchtype_id`, `map_id`, `maxplayers`, `description`, `started`
#'   (POSIXct, UTC), `duration_s`, `profile_id`, `civilization_id`, `team_id`,
#'   `won`, `rating_change`, `rating_before`, `rating_after`, `streak`,
#'   `wins`, `losses` and `xp_gained`.
#' @export
#' @examples
#' \dontrun{
#' get_player_matches(6174996)
#' }
get_player_matches <- function(profile_id, pause = 0) {
  if (length(profile_id) < 1 || anyNA(profile_id)) {
    stop("`profile_id` must contain at least one non-missing id.", call. = FALSE)
  }
  ao_check_nonnegative(pause, "pause")

  batches <- ao_batches(unique(as.integer(profile_id)), 10L)
  matches <- lapply(seq_along(batches), function(i) {
    if (i > 1L && pause > 0) {
      Sys.sleep(pause)
    }
    payload <- ao_request("getRecentMatchHistory", list(
      profile_ids = sprintf("[%s]", paste(batches[[i]], collapse = ","))
    ))
    parse_matches(payload)
  })

  ao_deduplicate_matches(tibble::as_tibble(do.call(rbind, matches)))
}
