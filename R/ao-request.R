# Centraliza HTTP para manter funcoes publicas sem transporte.

ao_request <- function(endpoint, query = list()) {
  url <- httr::modify_url(
    AOE2_HOST,
    path  = paste(AOE2_PATH, endpoint, sep = "/"),
    query = c(list(title = AOE2_TITLE), query)
  )

  resp <- httr::GET(url, httr::user_agent(AOE2_USER_AGENT))
  httr::stop_for_status(resp)

  payload <- jsonlite::fromJSON(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    simplifyVector = TRUE
  )

  ao_check_result(payload, endpoint)
  payload
}

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
