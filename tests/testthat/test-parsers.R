test_that("available leaderboards parse to a typed tibble", {
  payload <- fixture("available-leaderboards.json")
  ladders <- aoe2r:::parse_leaderboards(payload)
  civilizations <- aoe2r:::parse_civilizations(payload)

  expect_s3_class(ladders, "tbl_df")
  expect_equal(nrow(ladders), 17L)
  expect_equal(ladders$name[ladders$leaderboard_id == 3L], "SOLO_RM_RANKED")
  expect_equal(ladders$matchtype_ids[ladders$leaderboard_id == 4L], "7/8/9")
  expect_equal(nrow(civilizations), 62L)
  expect_true(all(c("civilization_id", "civilization") %in% names(civilizations)))
})

test_that("leaderboard rows join stats to the right player", {
  standings <- aoe2r:::parse_leaderboard(fixture("leaderboard-3.json"))
  top_player <- standings[standings$rank == 1L, ]

  expect_s3_class(standings, "tbl_df")
  expect_equal(nrow(standings), 3L)
  expect_equal(top_player$profile_id, 251265L)
  expect_equal(top_player$alias, "TAG_MbL_")
  expect_equal(top_player$rating, 3014L)
  expect_s3_class(standings$last_match, "POSIXct")
})

test_that("player profile preserves unranked ladders", {
  profile <- aoe2r:::parse_player_profile(fixture("player-profile-251265.json"))
  players <- aoe2r:::parse_profiles(fixture("player-matches-6174996.json"))

  expect_equal(nrow(profile), 7L)
  expect_true(all(profile$profile_id == 251265L))
  expect_equal(profile$rating[profile$leaderboard_id == 3L], 3014L)
  expect_true(any(profile$rank == -1L))
  expect_equal(nrow(players), 110L)
  expect_true(all(c("profile_id", "alias", "steam_id") %in% names(players)))
})

test_that("match history has one row per player", {
  matches <- aoe2r:::parse_matches(fixture("player-matches-6174996.json"))

  expect_s3_class(matches, "tbl_df")
  expect_equal(nrow(matches), 232L)
  expect_equal(length(unique(matches$match_id)), 53L)
  expect_equal(sum(matches$won), 116L)
  expect_equal(sum(matches$match_id == 511044310L), 6L)
  expect_true(all(matches$rating_after - matches$rating_before == matches$rating_change))
  expect_s3_class(matches$started, "POSIXct")
})

test_that("empty match history keeps the match schema", {
  matches <- aoe2r:::parse_matches(list(
    matchHistoryStats = data.frame(matchhistoryreportresults = list())
  ))

  expect_equal(nrow(matches), 0L)
  expect_equal(ncol(matches), 18L)
  expect_s3_class(matches$started, "POSIXct")
})
