#' Available ranked ladders
#'
#' Lists every leaderboard the Age of Empires II: Definitive Edition backend
#' knows about, together with the game types each one covers.
#'
#' Call this first: World\'s Edge adds ladders over time, so hard-coded
#' `leaderboard_id` values go stale. [get_leaderboard()] takes the
#' `leaderboard_id` returned here.
#'
#' @return A tibble with one row per ladder: `leaderboard_id`, `name`,
#'   `is_ranked` and `matchtype_ids` (game types joined by `/`).
#' @export
#' @examples
#' \dontrun{
#' get_available_leaderboards()
#' }
get_available_leaderboards <- function() {
  parse_leaderboards(ao_request("getAvailableLeaderboards"))
}
