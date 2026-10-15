#' Leaderboard standings
#'
#' Fetches the ranked players of one ladder. Requests larger than 200 rows are
#' paginated automatically.
#'
#' @param leaderboard_id Integer ladder id, as returned by
#'   [get_available_leaderboards()].
#' @param start Integer first rank to return (1 = best rank).
#' @param count Integer rows to return.
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
  ao_check_integer(leaderboard_id, "leaderboard_id", 1)
  ao_check_integer(start, "start", 1)
  ao_check_integer(count, "count", 1)

  starts <- seq.int(start, length.out = ceiling(count / 200), by = 200)
  pages <- lapply(starts, function(page_start) {
    page_count <- min(200L, start + count - page_start)
    payload <- ao_request("getLeaderBoard2", list(
      leaderboard_id = leaderboard_id,
      sortBy = 1,
      start = page_start,
      count = page_count
    ))
    parse_leaderboard(payload)
  })

  rows <- sum(vapply(pages, nrow, integer(1)))
  tibble::as_tibble(do.call(rbind, pages))[seq_len(min(count, rows)), ]
}
