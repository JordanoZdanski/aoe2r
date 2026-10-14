# aoe2r

`aoe2r` downloads Age of Empires II: Definitive Edition leaderboard, player
profile, and recent match-history data into analysis-ready tibbles.

The package uses the World's Edge backend consumed by the game client. This is
an unofficial, reverse-engineered service: endpoints and response formats can
change without notice.

## Installation

The package is not on CRAN. Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("JordanoZdanski/aoe2r")
```

## Usage

```r
library(aoe2r)

# Find the current leaderboard identifiers.
ladders <- get_available_leaderboards()

# Get the top 100 players in the 1v1 Random Map ladder.
leaderboard <- get_leaderboard(leaderboard_id = 3, count = 100)

# Get every recent completed match involving a player.
# The result has one row per player per match.
matches <- get_player_matches(profile_id = 6174996)

# Look up a player and their standing on every ladder.
profile <- get_player_profile(profile_id = 251265)
```

`get_player_profile()` also accepts an exact, case-sensitive `alias`:

```r
get_player_profile(alias = "TAG_MbL_")
```

Aliases are not unique. An alias lookup can return several players, so use
`profile_id` when an unambiguous identifier is available.

## Main functions

| Function | Returns |
|---|---|
| `get_available_leaderboards()` | One row per available ranked ladder. |
| `get_leaderboard()` | One row per player in a ladder. |
| `get_player_matches()` | One row per player per completed match. |
| `get_player_profile()` | One row per ladder associated with a player. |

Dates are returned as `POSIXct` in UTC. A `rank` of `-1` in a player profile
means that the player is not ranked on that ladder.

## Development

Tests use saved API responses and never make network requests. From the package
directory, run:

```bash
Rscript -e 'testthat::test_local(".")'
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check aoe2r_0.1.0.tar.gz --no-manual
```

---

# aoe2r

`aoe2r` baixa dados de leaderboard, perfil de jogador e histórico recente de
partidas de Age of Empires II: Definitive Edition para tibbles prontos para
análise.

O pacote usa o backend da World's Edge consumido pelo cliente do jogo. Trata-se
de um serviço não oficial, obtido por engenharia reversa: endpoints e formatos
de resposta podem mudar sem aviso.

## Instalação

O pacote ainda não está no CRAN. Instale a versão de desenvolvimento pelo
GitHub:

```r
install.packages("remotes")
remotes::install_github("JordanoZdanski/aoe2r")
```

## Uso

```r
library(aoe2r)

# Descobre os identificadores atuais das ladders.
ladders <- get_available_leaderboards()

# Traz os 100 melhores jogadores da ladder 1v1 Random Map.
leaderboard <- get_leaderboard(leaderboard_id = 3, count = 100)

# Traz todas as partidas recentes concluídas que envolvem um jogador.
# O resultado tem uma linha por jogador por partida.
matches <- get_player_matches(profile_id = 6174996)

# Busca um jogador e sua posição em cada ladder.
profile <- get_player_profile(profile_id = 251265)
```

`get_player_profile()` também aceita um `alias` exato, sensível a maiúsculas e
minúsculas:

```r
get_player_profile(alias = "TAG_MbL_")
```

Aliases não são únicos. Uma busca por alias pode devolver vários jogadores;
quando houver um identificador sem ambiguidade, use `profile_id`.

## Funções principais

| Função | Retorno |
|---|---|
| `get_available_leaderboards()` | Uma linha por ladder ranqueada disponível. |
| `get_leaderboard()` | Uma linha por jogador de uma ladder. |
| `get_player_matches()` | Uma linha por jogador por partida concluída. |
| `get_player_profile()` | Uma linha por ladder associada a um jogador. |

Datas são retornadas como `POSIXct` em UTC. Em um perfil, `rank = -1` significa
que o jogador não está ranqueado naquela ladder.

## Desenvolvimento

Os testes usam respostas da API salvas localmente e nunca fazem requisições de
rede. A partir da pasta do pacote, rode:

```bash
Rscript -e 'testthat::test_local(".")'
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check aoe2r_0.1.0.tar.gz --no-manual
```
