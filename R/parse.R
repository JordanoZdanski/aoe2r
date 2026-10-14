# Parse: resposta do servidor -> tibble, sem rede. `parse_*` sao puras e
# testaveis offline; `get_*` sao as funcoes publicas.

# O backend manda epoch Unix em inteiro cru, nao em texto ISO.
ao_as_date <- function(x) {
  if (is.null(x)) {
    return(as.POSIXct(character(), origin = "1970-01-01", tz = "UTC"))
  }
  as.POSIXct(as.numeric(x), origin = "1970-01-01", tz = "UTC")
}

# Abre um campo de uma linha de data.frame. `members` chega como lista-columna.
ao_first <- function(df, column) df[[column]][[1]]


# --- getAvailableLeaderboards ------------------------------------------------

parse_leaderboards <- function(payload) {
  lb <- payload$leaderboards

  matchtypes <- vapply(
    lb$leaderboardmap,
    function(m) {
      paste(vapply(m$matchtype_id, as.character, character(1)), collapse = "/")
    },
    character(1)
  )

  tibble::tibble(
    leaderboard_id = as.integer(lb$id),
    name           = as.character(lb$name),
    is_ranked      = as.logical(lb$isranked),
    matchtype_ids  = matchtypes
  )
}

# Civilizacoes vem no mesmo payload, em `races`, e ja com nome.
parse_civilizations <- function(payload) {
  tibble::tibble(
    civilization_id = as.integer(payload$races$id),
    civilization    = as.character(payload$races$name)
  )
}


# --- getLeaderBoard2 e getPersonalStat ---------------------------------------

# Ambos devolvem `statGroups` (quem e o jogador) e `leaderboardStats` (seus
# numeros) em arrays paralelos ligados por `statgroup_id` -- e em ordens
# diferentes. Unir por posicao daria o rating de um jogador no nome de outro,
# sem erro e sem NA, entao o match() por chave e obrigatorio.
parse_leaderboard <- function(payload) {
  stats <- payload$leaderboardStats
  groups <- payload$statGroups

  group_index <- match(stats$statgroup_id, groups$id)
  member <- groups$members[group_index]

  tibble::tibble(
    leaderboard_id = as.integer(stats$leaderboard_id),
    rank           = as.integer(stats$rank),
    profile_id     = as.integer(vapply(member, ao_first, numeric(1), column = "profile_id")),
    alias          = vapply(member, ao_first, character(1), column = "alias"),
    rating         = as.integer(stats$rating),
    wins           = as.integer(stats$wins),
    losses         = as.integer(stats$losses),
    streak         = as.integer(stats$streak),
    drops          = as.integer(stats$drops),
    rank_total     = as.integer(stats$ranktotal),
    last_match     = ao_as_date(stats$lastmatchdate)
  )
}

# Identidade: apelido, pais, nivel e SteamID64 (dentro do campo `name`, que
# vem como "/steam/76561198...").
parse_profiles <- function(payload) {
  prof <- payload$profiles
  if (is.null(prof)) {
    return(tibble::tibble(
      profile_id = integer(), alias = character(), country = character(),
      level = integer(), xp = integer(), steam_id = character()
    ))
  }

  tibble::tibble(
    profile_id = as.integer(prof$profile_id),
    alias      = as.character(prof$alias),
    country    = as.character(prof$country),
    level      = as.integer(prof$level),
    xp         = as.integer(prof$xp),
    steam_id   = sub("^/steam/", "", as.character(prof$name))
  )
}

# Uma linha por ladder do jogador, com os dados de identidade repetidos.
parse_player_profile <- function(payload) {
  ladder <- parse_leaderboard(payload)
  who <- payload$statGroups$members[[1]]

  tibble::tibble(
    profile_id     = as.integer(ao_first(who, "profile_id")),
    alias          = as.character(ao_first(who, "alias")),
    country        = as.character(ao_first(who, "country")),
    level          = as.integer(ao_first(who, "level")),
    steam_id       = sub("^/steam/", "", as.character(ao_first(who, "name"))),
    leaderboard_id = ladder$leaderboard_id,
    rank           = ladder$rank,
    rating         = ladder$rating,
    wins           = ladder$wins,
    losses         = ladder$losses,
    streak         = ladder$streak,
    drops          = ladder$drops,
    rank_total     = ladder$rank_total,
    last_match     = ladder$last_match
  )
}


# --- getRecentMatchHistory ---------------------------------------------------

parse_matches <- function(payload) {
  matches <- payload$matchHistoryStats
  if (is.null(matches) || nrow(matches) == 0) {
    return(empty_matches())
  }

  results <- matches$matchhistoryreportresults
  members <- matches$matchhistorymember

  players <- do.call(rbind, lapply(seq_along(results), function(i) {
    r <- results[[i]]
    m <- members[[i]]
    pos <- match(r$profile_id, m$profile_id)

    tibble::tibble(
      .partida        = i,
      profile_id      = as.integer(r$profile_id),
      civilization_id = as.integer(r$civilization_id),
      team_id         = as.integer(r$teamid),
      won             = as.logical(r$resulttype == 1L),
      xp_gained       = as.integer(r$xpgained),
      rating_before   = as.integer(m$oldrating[pos]),
      rating_after    = as.integer(m$newrating[pos]),
      rating_change   = as.integer(m$newrating[pos] - m$oldrating[pos]),
      streak          = as.integer(m$streak[pos]),
      wins            = as.integer(m$wins[pos]),
      losses          = as.integer(m$losses[pos])
    )
  }))

  i <- players$.partida

  tibble::tibble(
    match_id        = as.integer(matches$id)[i],
    matchtype_id    = as.integer(matches$matchtype_id)[i],
    map_id          = as.character(matches$mapname)[i],
    maxplayers      = as.integer(matches$maxplayers)[i],
    description     = as.character(matches$description)[i],
    started         = ao_as_date(matches$startgametime)[i],
    duration_s      = as.integer(matches$completiontime[i] - matches$startgametime[i]),
    profile_id      = players$profile_id,
    civilization_id = players$civilization_id,
    team_id         = players$team_id,
    won             = players$won,
    rating_change   = players$rating_change,
    rating_before   = players$rating_before,
    rating_after    = players$rating_after,
    streak          = players$streak,
    wins            = players$wins,
    losses          = players$losses,
    xp_gained       = players$xp_gained
  )
}

# Formato preservado mesmo vazio, para nao quebrar um pipeline no meio.
# Colunas a mao de proposito: nao podem vir de parse_matches(), que e quem
# chama esta funcao quando o jogador nao tem partidas.
empty_matches <- function() {
  tibble::tibble(
    match_id        = integer(),
    matchtype_id    = integer(),
    map_id          = character(),
    maxplayers      = integer(),
    description     = character(),
    started         = ao_as_date(NULL),
    duration_s      = integer(),
    profile_id      = integer(),
    civilization_id = integer(),
    team_id         = integer(),
    won             = logical(),
    rating_change   = integer(),
    rating_before   = integer(),
    rating_after    = integer(),
    streak          = integer(),
    wins            = integer(),
    losses          = integer(),
    xp_gained       = integer()
  )
}
