test_that("request result codes are checked", {
  expect_silent(aoe2r:::ao_check_result(list(result = list(code = 0L)), "test"))
  expect_error(
    aoe2r:::ao_check_result(list(result = list(code = 5L, message = "NOT_FOUND")), "test"),
    "code 5: NOT_FOUND"
  )
  expect_error(aoe2r:::ao_check_result(list(result = list()), "test"), "no 'result.code'")
})

test_that("public functions reject invalid inputs before a request", {
  expect_error(get_leaderboard(integer()), "greater than or equal to 1")
  expect_error(get_leaderboard(3, count = 0), "greater than or equal to 1")
  expect_error(get_player_matches(integer()), "at least one")
  expect_error(get_player_matches(1, pause = -1), "non-negative")
  expect_error(get_player_profile(), "exactly one")
  expect_error(get_player_profile(profile_id = 1, alias = "player"), "exactly one")
})

test_that("retry status identifies transient server failures", {
  expect_true(aoe2r:::ao_retry_status(429))
  expect_true(aoe2r:::ao_retry_status(500))
  expect_false(aoe2r:::ao_retry_status(400))
})
