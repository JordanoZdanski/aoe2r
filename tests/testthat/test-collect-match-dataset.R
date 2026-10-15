test_that("large requests are split into batches and deduplicated", {
  players <- tibble::tibble(profile_id = 1:12)
  requested <- list()

  testthat::local_mocked_bindings(
    get_leaderboard = function(...) players,
    get_player_matches = function(profile_id, pause) {
      requested[[length(requested) + 1L]] <<- profile_id
      tibble::tibble(
        match_id = c(999L, profile_id),
        profile_id = c(1L, profile_id),
        started = as.POSIXct(rep("2026-10-14", length(profile_id)), tz = "UTC")
      )
    },
    .package = "aoe2r"
  )

  dataset <- collect_match_dataset(n_profiles = 12, pause = 0)

  expect_equal(length(requested), 2L)
  expect_equal(length(requested[[1]]), 10L)
  expect_equal(nrow(dataset), 13L)
  expect_s3_class(dataset, "aoe2r_match_dataset")
  expect_equal(attr(dataset, "collection_metadata")$unique_matches, 13L)
})

test_that("checkpointed collection resumes without new requests", {
  path <- tempfile("aoe2r-collection-")
  players <- tibble::tibble(profile_id = 1:2)

  testthat::local_mocked_bindings(
    get_leaderboard = function(...) players,
    get_player_matches = function(profile_id, pause) {
      tibble::tibble(match_id = profile_id, profile_id = profile_id)
    },
    .package = "aoe2r"
  )
  first <- collect_match_dataset(n_profiles = 2, path = path, pause = 0)

  testthat::local_mocked_bindings(
    get_leaderboard = function(...) stop("should not request leaderboard"),
    get_player_matches = function(...) stop("should not request matches"),
    .package = "aoe2r"
  )
  second <- collect_match_dataset(n_profiles = 2, path = path, pause = 0)

  expect_equal(first, second)
  expect_error(collect_match_dataset(n_profiles = 3, path = path), "does not match")
  unlink(path, recursive = TRUE)
})

test_that("saved datasets preserve metadata", {
  dataset <- tibble::tibble(match_id = 1L, profile_id = 1L)
  class(dataset) <- c("aoe2r_match_dataset", class(dataset))
  attr(dataset, "collection_metadata") <- list(rows = 1L)
  file <- tempfile(fileext = ".rds")

  expect_silent(save_match_dataset(dataset, file))
  expect_equal(readRDS(file), dataset)
  expect_error(save_match_dataset(dataset, file), "already exists")
})
