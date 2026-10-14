coleta_validar_numero <- function(x, nome, minimo) {
  if (length(x) != 1 || is.na(x) || !is.finite(x) || x < minimo || x != as.integer(x)) {
    stop(sprintf("`%s` deve ser um inteiro maior ou igual a %d.", nome, minimo),
         call. = FALSE)
  }
  as.integer(x)
}

coleta_lotes <- function(x, tamanho) {
  split(x, ceiling(seq_along(x) / tamanho))
}

# Escreve em arquivo temporario para nao deixar checkpoint parcial.
coleta_salvar_rds <- function(objeto, caminho) {
  temporario <- tempfile(pattern = ".coleta-", tmpdir = dirname(caminho))
  on.exit(unlink(temporario), add = TRUE)
  saveRDS(objeto, temporario)

  if (!file.rename(temporario, caminho)) {
    stop(sprintf("Nao foi possivel salvar '%s'.", caminho), call. = FALSE)
  }
}

# Falhas transitorias esperam mais a cada tentativa.
coleta_tentar <- function(funcao, ..., tentativas, espera_inicial_s) {
  for (tentativa in seq_len(tentativas)) {
    resultado <- tryCatch(funcao(...), error = identity)
    if (!inherits(resultado, "error")) {
      return(resultado)
    }

    if (tentativa == tentativas) {
      stop(
        sprintf("Falhou apos %d tentativas: %s", tentativas, conditionMessage(resultado)),
        call. = FALSE
      )
    }

    Sys.sleep(espera_inicial_s * 2 ^ (tentativa - 1L))
  }
}

coleta_perfis_ladder <- function(leaderboard_id, n_profiles, inicio,
                                  tentativas, espera_inicial_s,
                                  buscar_ladder) {
  perfis <- integer()
  proximo_inicio <- inicio

  while (length(perfis) < n_profiles) {
    quantidade <- min(200L, n_profiles - length(perfis))
    pagina <- coleta_tentar(
      buscar_ladder,
      leaderboard_id = leaderboard_id,
      start = proximo_inicio,
      count = quantidade,
      tentativas = tentativas,
      espera_inicial_s = espera_inicial_s
    )

    if (nrow(pagina) == 0) {
      break
    }

    perfis <- unique(c(perfis, as.integer(pagina$profile_id)))
    proximo_inicio <- proximo_inicio + quantidade
  }

  if (length(perfis) < n_profiles) {
    stop("A leaderboard nao tem perfis suficientes para esta coleta.", call. = FALSE)
  }

  perfis[seq_len(n_profiles)]
}

coleta_deduplicar <- function(partidas_jogadores) {
  chave_jogador <- paste(partidas_jogadores$match_id,
                         partidas_jogadores$profile_id,
                         sep = "-")
  partidas_jogadores[!duplicated(chave_jogador), , drop = FALSE]
}

coleta_resumir_partidas <- function(partidas_jogadores) {
  colunas_partida <- c(
    "match_id", "matchtype_id", "map_id", "maxplayers", "description",
    "started", "duration_s"
  )
  primeira_linha <- !duplicated(partidas_jogadores$match_id)
  partidas <- partidas_jogadores[primeira_linha, colunas_partida, drop = FALSE]
  jogadores_por_partida <- table(partidas_jogadores$match_id)
  partidas$players_observed <- as.integer(
    jogadores_por_partida[as.character(partidas$match_id)]
  )
  partidas
}

# Coleta historicos recentes de perfis de uma leaderboard em lotes retomaveis.
coletar_partidas_ladder <- function(
    leaderboard_id = 3,
    n_profiles = 200,
    inicio = 1,
    pausa_s = 1,
    tentativas = 3,
    espera_inicial_s = 2,
    pasta_saida = "dados",
    continuar = TRUE,
    .buscar_ladder = aoe2r::get_leaderboard,
    .buscar_partidas = aoe2r::get_player_matches) {
  leaderboard_id <- coleta_validar_numero(leaderboard_id, "leaderboard_id", 1)
  n_profiles <- coleta_validar_numero(n_profiles, "n_profiles", 1)
  inicio <- coleta_validar_numero(inicio, "inicio", 1)
  tentativas <- coleta_validar_numero(tentativas, "tentativas", 1)

  if (length(pausa_s) != 1 || !is.numeric(pausa_s) || is.na(pausa_s) ||
      !is.finite(pausa_s) || pausa_s < 0) {
    stop("`pausa_s` deve ser um numero maior ou igual a zero.", call. = FALSE)
  }
  if (length(espera_inicial_s) != 1 || !is.numeric(espera_inicial_s) ||
      is.na(espera_inicial_s) || !is.finite(espera_inicial_s) || espera_inicial_s < 0) {
    stop("`espera_inicial_s` deve ser um numero maior ou igual a zero.", call. = FALSE)
  }

  pasta_coleta <- file.path(pasta_saida, sprintf("ladder-%d", leaderboard_id))
  pasta_lotes <- file.path(pasta_coleta, "lotes")
  arquivo_manifesto <- file.path(pasta_coleta, "manifesto.rds")
  dir.create(pasta_lotes, recursive = TRUE, showWarnings = FALSE)

  configuracao <- list(
    leaderboard_id = leaderboard_id,
    n_profiles = n_profiles,
    inicio = inicio
  )

  if (file.exists(arquivo_manifesto)) {
    if (!isTRUE(continuar)) {
      stop("Ja existe uma coleta nesta pasta. Use `continuar = TRUE` ou outra pasta.",
           call. = FALSE)
    }

    manifesto <- readRDS(arquivo_manifesto)
    if (!identical(manifesto$configuracao, configuracao)) {
      stop("A configuracao nao coincide com o manifesto salvo.", call. = FALSE)
    }
  } else {
    perfis <- coleta_perfis_ladder(
      leaderboard_id = leaderboard_id,
      n_profiles = n_profiles,
      inicio = inicio,
      tentativas = tentativas,
      espera_inicial_s = espera_inicial_s,
      buscar_ladder = .buscar_ladder
    )
    manifesto <- list(
      configuracao = configuracao,
      profile_ids = perfis,
      criado_em = Sys.time()
    )
    coleta_salvar_rds(manifesto, arquivo_manifesto)
  }

  lotes <- coleta_lotes(manifesto$profile_ids, 10L)
  arquivos_lotes <- file.path(pasta_lotes, sprintf("lote-%04d.rds", seq_along(lotes)))

  for (i in seq_along(lotes)) {
    if (file.exists(arquivos_lotes[i])) {
      next
    }
    if (i > 1L && pausa_s > 0) {
      Sys.sleep(pausa_s)
    }

    message(sprintf("Coletando lote %d de %d.", i, length(lotes)))
    partidas <- coleta_tentar(
      .buscar_partidas,
      profile_id = lotes[[i]],
      tentativas = tentativas,
      espera_inicial_s = espera_inicial_s
    )
    coleta_salvar_rds(
      list(profile_ids = lotes[[i]], partidas = partidas, coletado_em = Sys.time()),
      arquivos_lotes[i]
    )
  }

  resultados <- lapply(arquivos_lotes, readRDS)
  bruto <- do.call(rbind, lapply(resultados, `[[`, "partidas"))
  partidas_jogadores <- coleta_deduplicar(bruto)
  partidas <- coleta_resumir_partidas(partidas_jogadores)

  metadados <- list(
    configuracao = configuracao,
    profile_ids = manifesto$profile_ids,
    lotes = length(lotes),
    linhas_brutas = nrow(bruto),
    linhas_jogadores = nrow(partidas_jogadores),
    partidas_unicas = nrow(partidas),
    concluido_em = Sys.time()
  )

  coleta_salvar_rds(partidas_jogadores,
                     file.path(pasta_coleta, "partidas-jogadores.rds"))
  coleta_salvar_rds(partidas, file.path(pasta_coleta, "partidas.rds"))
  coleta_salvar_rds(metadados, file.path(pasta_coleta, "metadados.rds"))

  list(
    partidas_jogadores = partidas_jogadores,
    partidas = partidas,
    metadados = metadados,
    pasta = pasta_coleta
  )
}
