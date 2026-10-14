fixture <- function(name) {
  jsonlite::fromJSON(
    testthat::test_path("..", "fixtures", name),
    simplifyVector = TRUE
  )
}
