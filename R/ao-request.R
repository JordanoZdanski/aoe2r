# Centraliza HTTP para manter funcoes publicas sem transporte.

ao_request <- function(endpoint, query = list(), retries = 3, timeout_s = 30) {
  url <- httr::modify_url(
    AOE2_HOST,
    path  = paste(AOE2_PATH, endpoint, sep = "/"),
    query = c(list(title = AOE2_TITLE), query)
  )

  retries <- ao_check_integer(retries, "retries", 1)
  ao_check_nonnegative(timeout_s, "timeout_s")

  resp <- NULL
  for (attempt in seq_len(retries)) {
    resp <- tryCatch(
      httr::GET(url, httr::user_agent(AOE2_USER_AGENT), httr::timeout(timeout_s)),
      error = identity
    )
    if (!inherits(resp, "error")) {
      status <- httr::status_code(resp)
      if (!ao_retry_status(status) || attempt == retries) {
        break
      }
    } else if (attempt == retries) {
      stop(sprintf("Request to '%s' failed: %s.", endpoint, conditionMessage(resp)),
           call. = FALSE)
    }
    Sys.sleep(2 ^ (attempt - 1L))
  }

  httr::stop_for_status(resp)

  payload <- jsonlite::fromJSON(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    simplifyVector = TRUE
  )

  ao_check_result(payload, endpoint)
  payload
}

ao_retry_status <- function(status) status == 429 || status >= 500

# Erros de dominio chegam em HTTP 200; verificar result.code.
ao_check_result <- function(payload, endpoint) {
  result <- payload$result

  if (is.null(result$code)) {
    stop(sprintf("Endpoint '%s' returned no 'result.code'.", endpoint),
         call. = FALSE)
  }

  if (!identical(as.integer(result$code), 0L)) {
    stop(sprintf("Request to '%s' failed (code %s: %s).",
                 endpoint, result$code, result$message %||% "no message"),
         call. = FALSE)
  }

  invisible(payload)
}

# Alternativa para NULL.
`%||%` <- function(x, y) if (is.null(x)) y else x
