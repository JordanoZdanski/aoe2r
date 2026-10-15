# aoe2r

`aoe2r` downloads Age of Empires II: Definitive Edition data into
analysis-ready tibbles: leaderboards, player profiles, and match histories.

The package uses the World's Edge backend consumed by the game client. This is
an unofficial, reverse-engineered service: endpoints and response formats can
change without notice.

## Installation

```r
install.packages("remotes")
remotes::install_github("JordanoZdanski/aoe2r")
```

## Quick start

```r
library(aoe2r)

# Current leaderboard identifiers (ladder 3 is 1v1 Random Map).
get_available_leaderboards()

# Top 1000 players of a ladder; pagination is automatic.
ranking <- get_leaderboard(leaderboard_id = 3, count = 1000)

# Recent matches of any number of players; requests are batched
# automatically and repeated rows are removed.
matches <- get_player_matches(ranking$profile_id[1:100])

# A player's standing on every ladder (or use alias = "TAG_MbL_").
get_player_profile(profile_id = 251265)
```

## Building a dataset

One call collects the recent history of many leaderboard players:

```r
dataset <- collect_match_dataset(
  leaderboard_id = 3,
  n_profiles = 1000,
  path = "data/collection-rm",   # checkpoints; use NULL to keep it in memory
  resume = TRUE
)
```

The result is a tibble with one row per player per match, deduplicated by
`match_id` + `profile_id`. Save it once and share the file:

```r
save_match_dataset(dataset, "data/dataset-rm.rds")

# Anyone can reproduce your analysis from the same snapshot:
dataset <- readRDS("data/dataset-rm.rds")
```

## Live data vs. reproducibility

The backend is a live service: calling `collect_match_dataset()` again on
another day returns the state available at that time, which may differ from a
previous collection. Two guarantees follow:

- **Reproducible analysis** — share the saved RDS snapshot; it always contains
  the same rows.
- **Fresh data** — call the collection again (use a new `path` for a fresh
  checkpoint set). There is no seed that freezes the server.

A `path` that already exists is resumed, not silently refreshed.

## Notes for machine learning

- Split training and test sets **by `match_id`**: players of the same match
  belong in the same fold.
- Do not use post-match columns (`rating_after`, `rating_change`,
  `duration_s`, `xp_gained`) as predictors of the match result.
- Dates are `POSIXct` in UTC; a `rank` of `-1` in a player profile means the
  player is unranked on that ladder.

## Functions

| Function | Returns |
|---|---|
| `get_available_leaderboards()` | One row per available ranked ladder. |
| `get_leaderboard()` | One row per player in a ladder; `count` over 200 is paginated. |
| `get_player_matches()` | One row per player per completed match; inputs over 10 ids are batched. |
| `get_player_profile()` | One row per ladder associated with a player. |
| `collect_match_dataset()` | A deduplicated player-match dataset, with optional checkpoints. |
| `save_match_dataset()` | Writes a dataset to an RDS file without overwriting by accident. |

## Development

Tests use saved API responses and never make network requests. From the package
directory, run:

```bash
Rscript -e 'testthat::test_local(".")'
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check aoe2r_0.2.0.tar.gz --no-manual
```

---

# aoe2r

`aoe2r` baixa dados de Age of Empires II: Definitive Edition para tibbles
prontos para análise: leaderboards, perfis de jogador e históricos de partidas.

O pacote usa o backend da World's Edge consumido pelo cliente do jogo. Trata-se
de um serviço não oficial, obtido por engenharia reversa: endpoints e formatos
de resposta podem mudar sem aviso.

## Instalação

```r
install.packages("remotes")
remotes::install_github("JordanoZdanski/aoe2r")
```

## Começo rápido

```r
library(aoe2r)

# Identificadores atuais das ladders (a 3 e 1v1 Random Map).
get_available_leaderboards()

# Top 1000 jogadores de uma ladder; a paginacao e automatica.
ranking <- get_leaderboard(leaderboard_id = 3, count = 1000)

# Partidas recentes de qualquer quantidade de jogadores; as chamadas
# sao divididas em lotes automaticamente e linhas repetidas sao removidas.
matches <- get_player_matches(ranking$profile_id[1:100])

# Posicao de um jogador em cada ladder (ou use alias = "TAG_MbL_").
get_player_profile(profile_id = 251265)
```

## Montando um dataset

Uma chamada coleta o histórico recente de muitos jogadores de uma leaderboard:

```r
dataset <- collect_match_dataset(
  leaderboard_id = 3,
  n_profiles = 1000,
  path = "dados/coleta-rm",   # checkpoints; use NULL para manter em memoria
  resume = TRUE
)
```

O resultado é um tibble com uma linha por jogador por partida, deduplicado por
`match_id` + `profile_id`. Salve uma vez e compartilhe o arquivo:

```r
save_match_dataset(dataset, "dados/dataset-rm.rds")

# Qualquer pessoa reproduz sua analise a partir do mesmo snapshot:
dataset <- readRDS("dados/dataset-rm.rds")
```

## Dados vivos vs. reprodutibilidade

O backend é um serviço vivo: chamar `collect_match_dataset()` em outra data
retorna o estado disponível naquele momento, que pode ser diferente de uma
coleta anterior. Duas garantias decorrem disso:

- **Análise reproduzível** — compartilhe o snapshot RDS salvo; ele sempre tem
  as mesmas linhas.
- **Dados atualizados** — chame a coleta novamente (use um novo `path` para
  novos checkpoints). Não existe seed que congele o servidor.

Um `path` que já existe é retomado, não atualizado silenciosamente.

## Cuidados para machine learning

- Divida treino e teste **por `match_id`**: jogadores da mesma partida devem
  ficar no mesmo grupo.
- Não use colunas pós-partida (`rating_after`, `rating_change`, `duration_s`,
  `xp_gained`) como preditores do resultado.
- Datas são `POSIXct` em UTC; `rank = -1` em um perfil significa que o jogador
  não está ranqueado naquela ladder.

## Funções

| Função | Retorno |
|---|---|
| `get_available_leaderboards()` | Uma linha por ladder ranqueada disponível. |
| `get_leaderboard()` | Uma linha por jogador; `count` acima de 200 é paginado. |
| `get_player_matches()` | Uma linha por jogador por partida; mais de 10 ids vão em lotes. |
| `get_player_profile()` | Uma linha por ladder associada a um jogador. |
| `collect_match_dataset()` | Dataset jogador-partida deduplicado, com checkpoints opcionais. |
| `save_match_dataset()` | Grava um dataset em RDS sem sobrescrever por acidente. |

## Desenvolvimento

Os testes usam respostas da API salvas localmente e nunca fazem requisições de
rede. A partir da pasta do pacote, rode:

```bash
Rscript -e 'testthat::test_local(".")'
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check aoe2r_0.2.0.tar.gz --no-manual
```
