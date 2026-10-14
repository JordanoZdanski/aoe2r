#' Player profile and ladder standings
#'
#' Looks a player up by `profile_id` or by in-game `alias`, and returns their
#' standing on every ladder they appear in.
#'
#' The backend allows only one identifier per request. Aliases are neither
#' unique nor case-insensitive: `alias = "Hera"` matches ten different
#' players. Each one comes back on its own row, distinguished by `country`
#' and `level`, so you can pick the right one.
#'
#' @param profile_id Integer Relic profile id. Mutually exclusive with `alias`.
#' @param alias Character in-game name, matched exactly and case-sensitively.
#'
#' @return A tibble with one row per ladder: `profile_id`, `alias`, `country`,
#'   `level`, `steam_id`, `leaderboard_id`, `rank`, `rating`, `wins`,
#'   `losses`, `streak`, `drops`, `rank_total` and `last_match`.
#'   A `rank` of `-1` means the player is not ranked on that ladder.
#' @export
#' @examples
#' \dontrun{
#' get_player_profile(profile_id = 6174996)
#' get_player_profile(alias = "TAG_MbL_")
#' }
get_player_profile <- function(profile_id = NULL, alias = NULL) {
  if (is.null(profile_id) == is.null(alias)) {
    stop("Supply exactly one of `profile_id` or `alias`.",
         call. = FALSE)
  }

  query <- if (is.null(profile_id)) {
    list(aliases = sprintf('["%s"]', alias))
  } else {
    list(profile_ids = sprintf("[%s]", paste(profile_id, collapse = ",")))
  }

  parse_player_profile(ao_request("getPersonalStat", query))
}
