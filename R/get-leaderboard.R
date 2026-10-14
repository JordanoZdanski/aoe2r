#' Leaderboard standings
#'
#' Fetches the ranked players of one ladder. Pagination is 1-based and the
#' server rejects `count` above 200 with an HTTP 400, so oversized requests are
#' caught here with a readable message instead.
#'
#' @param leaderboard_id Integer ladder id, as returned by
#'   [get_available_leaderboards()].
#' @param start Integer first rank to return (1 = best rank).
#' @param count Integer rows to return, at most 200.
#'
#' @return A tibble with one row per player: `leaderboard_id`, `rank`,
#'   `profile_id`, `alias`, `rating`, `wins`, `losses`, `streak`, `drops`,
#'   `rank_total` and `last_match` (POSIXct, UTC).
#' @export
#' @examples
#' \dontrun{
#' get_leaderboard(leaderboard_id = 3, count = 100)
#' }
get_leaderboard <- function(leaderboard_id, start = 1, count = 100) {
  if (length(leaderboard_id) != 1 || is.na(leaderboard_id)) {
    stop("`leaderboard_id` must be a single number.", call. = FALSE)
  }
  if (count > 200) {
    stop("`count` cannot exceed 200; the server rejects it with HTTP 400.",
         call. = FALSE)
  }

  payload <- ao_request("getLeaderBoard2", list(
    leaderboard_id = leaderboard_id,
    sortBy = 1,
    start = start,
    count = count
  ))

  parse_leaderboard(payload)
}
