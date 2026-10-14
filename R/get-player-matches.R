#' Match history for one or more players
#'
#' Returns completed matches as one row **per player**, not per match, so the
#' result feeds straight into tidymodels without `tidyr::unnest()`.
#'
#' Several players can be requested at once. The backend accepts up to ten
#' `profile_id` per call and returns the full history of every player named,
#' including the opponents they faced -- so ten ids easily yield thousands of
#' rows in a single request.
#'
#' Only finished matches appear. There is no endpoint for in-progress games.
#'
#' @param profile_id Integer Relic profile id (or a vector of up to ten). Get
#'   one from [get_leaderboard()] or [get_player_profile()].
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
get_player_matches <- function(profile_id) {
  if (length(profile_id) < 1 || length(profile_id) > 10) {
    stop("`profile_id` must contain between 1 and 10 ids.", call. = FALSE)
  }

  payload <- ao_request("getRecentMatchHistory", list(
    # O endpoint espera um array JSON na URL: [1,2,3].
    profile_ids = sprintf("[%s]", paste(profile_id, collapse = ","))
  ))

  parse_matches(payload)
}
