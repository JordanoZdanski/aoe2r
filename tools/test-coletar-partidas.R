source(file.path("tools", "coletar-partidas.R"))

buscar_ladder_falsa <- function(leaderboard_id, start, count) {
  data.frame(profile_id = seq.int(start, length.out = count))
}

buscar_partidas_falsa <- function(profile_id) {
  n <- length(profile_id)
  data.frame(
    match_id = c(999L, profile_id),
    matchtype_id = rep(6L, n + 1L),
    map_id = rep("Arabia.rms", n + 1L),
    maxplayers = rep(2L, n + 1L),
    description = rep("AUTOMATCH", n + 1L),
    started = as.POSIXct(rep("2026-10-14 00:00:00", n + 1L), tz = "UTC"),
    duration_s = rep(1200L, n + 1L),
    profile_id = c(1L, profile_id),
    civilization_id = rep(1L, n + 1L),
    team_id = rep(1L, n + 1L),
    won = rep(TRUE, n + 1L),
    rating_change = rep(10L, n + 1L),
    rating_before = rep(1000L, n + 1L),
    rating_after = rep(1010L, n + 1L),
    streak = rep(1L, n + 1L),
    wins = rep(1L, n + 1L),
    losses = rep(0L, n + 1L),
    xp_gained = rep(1L, n + 1L)
  )
}

pasta_teste <- tempfile("coleta-")
resultado <- coletar_partidas_ladder(
  n_profiles = 12,
  pausa_s = 0,
  tentativas = 1,
  pasta_saida = pasta_teste,
  .buscar_ladder = buscar_ladder_falsa,
  .buscar_partidas = buscar_partidas_falsa
)

stopifnot(
  resultado$metadados$lotes == 2L,
  resultado$metadados$linhas_brutas == 14L,
  resultado$metadados$linhas_jogadores == 13L,
  resultado$metadados$partidas_unicas == 13L,
  file.exists(file.path(resultado$pasta, "partidas-jogadores.rds")),
  file.exists(file.path(resultado$pasta, "partidas.rds")),
  file.exists(file.path(resultado$pasta, "metadados.rds"))
)

nao_deve_chamar <- function(...) {
  stop("Uma coleta retomada nao deve requisitar lotes salvos.")
}

resultado_retomado <- coletar_partidas_ladder(
  n_profiles = 12,
  pausa_s = 0,
  tentativas = 1,
  pasta_saida = pasta_teste,
  .buscar_ladder = nao_deve_chamar,
  .buscar_partidas = nao_deve_chamar
)

tentativas_feitas <- 0L
resultado_tentativa <- coleta_tentar(
  function() {
    tentativas_feitas <<- tentativas_feitas + 1L
    if (tentativas_feitas < 3L) {
      stop("Falha transitoria.")
    }
    "ok"
  },
  tentativas = 3,
  espera_inicial_s = 0
)

stopifnot(
  resultado_retomado$metadados$linhas_jogadores == 13L,
  identical(resultado_tentativa, "ok"),
  tentativas_feitas == 3L,
  inherits(
    try(coletar_partidas_ladder(n_profiles = 1, pausa_s = Inf), silent = TRUE),
    "try-error"
  ),
  inherits(
    try(coletar_partidas_ladder(n_profiles = 1, espera_inicial_s = "x"),
        silent = TRUE),
    "try-error"
  )
)

unlink(pasta_teste, recursive = TRUE)
cat("Coletor testado com dados simulados.\n")
