# Coleta de partidas para estudo

`coletar-partidas.R` fica fora do pacote `aoe2r`. O pacote continua com as
quatro funcoes do v0.1.0; este script usa essas funcoes para construir uma base
local maior para analise e ML.

## Uso

No R, a partir da raiz do repositorio clonado:

```r
source("tools/coletar-partidas.R")

coleta <- coletar_partidas_ladder(
  leaderboard_id = 3,
  n_profiles = 200,
  pausa_s = 1
)
```

## Argumentos

| Argumento | Padrao | Uso |
|---|---:|---|
| `leaderboard_id` | `3` | Ladder usada para obter os perfis iniciais. A 3 e 1v1 Random Map. |
| `n_profiles` | `200` | Quantidade de perfis da leaderboard que sera consultada. |
| `inicio` | `1` | Rank inicial na leaderboard. `201`, por exemplo, inicia no segundo grupo de 200 jogadores. |
| `pausa_s` | `1` | Segundos entre novos lotes. Use zero somente em testes pequenos. |
| `tentativas` | `3` | Numero maximo de tentativas para uma chamada que falhar. |
| `espera_inicial_s` | `2` | Espera antes da segunda tentativa; a espera dobra a cada falha. |
| `pasta_saida` | `"dados"` | Pasta-base para checkpoints e resultados. |
| `continuar` | `TRUE` | Retoma checkpoints existentes em vez de consultar novamente os lotes salvos. |

O retorno contem:

- `partidas_jogadores`: uma linha por jogador por partida;
- `partidas`: uma linha por partida, com `players_observed`;
- `metadados`: configuracao, perfis consultados e contagens;
- `pasta`: local dos arquivos salvos.

Os arquivos ficam em `dados/ladder-3/` por padrao:

```text
manifesto.rds
lotes/lote-0001.rds
partidas-jogadores.rds
partidas.rds
metadados.rds
```

`dados/` esta no `.gitignore`: resultados da API mudam ao longo do tempo e nao
devem ser versionados junto do codigo.

## Explorar o resultado

```r
# Resumo da coleta e caminho dos arquivos salvos.
coleta$metadados
coleta$pasta

# Uma observacao por jogador por partida: base indicada para modelagem.
head(coleta$partidas_jogadores)
table(coleta$partidas_jogadores$won)

# Uma observacao por partida: sem repetir jogadores.
head(coleta$partidas)
sort(table(coleta$partidas$map_id), decreasing = TRUE)
```

Para abrir os resultados em outra sessao R, sem fazer nova requisicao:

```r
partidas_jogadores <- readRDS("dados/ladder-3/partidas-jogadores.rds")
partidas <- readRDS("dados/ladder-3/partidas.rds")
metadados <- readRDS("dados/ladder-3/metadados.rds")
```

## Retomada

Cada lote de no maximo dez perfis e salvo logo apos uma resposta bem-sucedida.
Se a coleta parar, execute exatamente a mesma chamada novamente:

```r
coleta <- coletar_partidas_ladder(
  leaderboard_id = 3,
  n_profiles = 200,
  pausa_s = 1,
  continuar = TRUE
)
```

Lotes com arquivo salvo nao sao requisitados outra vez. A configuracao precisa
ser a mesma do manifesto; para outra coleta, use outro `leaderboard_id` ou
outro diretorio em `pasta_saida`.

## Cuidado com a API

- Cada chamada de historico aceita no maximo dez `profile_id`.
- A funcao espera `pausa_s` segundos entre novos lotes; o padrao e um segundo.
- Falhas sao tentadas tres vezes, com espera de 2 e 4 segundos antes das
  tentativas seguintes.
- A API devolve apenas historico recente. `n_profiles` aumenta a quantidade de
  jogadores e partidas, nao a profundidade temporal de cada historico.
- Perfis vindos de uma leaderboard formam uma amostra enviesada para aquela
  leaderboard e faixa de ranking.

## Deduplicacao

O endpoint pode devolver a mesma observacao em lotes diferentes, pois jogadores
da amostra jogam entre si. A chave de deduplicacao e:

```text
match_id + profile_id
```

Usar apenas `match_id` apagaria os outros jogadores de uma mesma partida. O
objeto `partidas` oferece a visao deduplicada por `match_id`, sem colunas de
jogador.

## Teste sem rede

```bash
Rscript tools/test-coletar-partidas.R
```

O teste usa respostas simuladas, verifica os dois lotes, a deduplicacao, os
arquivos de checkpoint e a saida final. Nenhuma requisicao e feita a API.
