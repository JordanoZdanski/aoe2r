test_that("request result codes are checked", {
  expect_silent(aoe2r:::ao_check_result(list(result = list(code = 0L)), "test"))
  expect_error(
    aoe2r:::ao_check_result(list(result = list(code = 5L, message = "NOT_FOUND")), "test"),
    "code 5: NOT_FOUND"
  )
  expect_error(aoe2r:::ao_check_result(list(result = list()), "test"), "no 'result.code'")
})

test_that("public functions reject invalid inputs before a request", {
  expect_error(get_leaderboard(integer()), "single number")
  expect_error(get_leaderboard(3, count = 201), "cannot exceed 200")
  expect_error(get_player_matches(integer()), "between 1 and 10")
  expect_error(get_player_matches(1:11), "between 1 and 10")
  expect_error(get_player_profile(), "exactly one")
  expect_error(get_player_profile(profile_id = 1, alias = "player"), "exactly one")
})
