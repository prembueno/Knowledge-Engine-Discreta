# Knowledge Engine — Copas do Mundo

Projeto de Lógica e Matemática Discreta (2026/1, Insper).

A ideia é montar uma base de conhecimento em Prolog a partir de um dataset público e responder perguntas usando lógica de primeira ordem (queries). Aqui o dataset escolhido foi o histórico das Copas do Mundo da FIFA (1930–2014).

## Dataset

Fonte: [FIFA World Cup no Kaggle](https://www.kaggle.com/datasets/abecklas/fifa-world-cup), arquivo `WorldCups.csv`. São 20 linhas, uma por edição da Copa.

Selecionei as 10 colunas do CSV (mistura de qualitativas e quantitativas):

- `Year` (int) — ano da edição
- `Country` — país-sede
- `Winner` — campeão
- `Runners-Up` — vice
- `Third` — terceiro
- `Fourth` — quarto
- `GoalsScored` (int) — total de gols
- `QualifiedTeams` (int) — número de seleções
- `MatchesPlayed` (int) — total de partidas
- `Attendance` (int) — público total

Cada linha vira um fato Prolog:

```prolog
copa(Ano, Sede, Campeao, Vice, Terceiro, Quarto, Gols, TimesQualificados, Partidas, Publico).
```

Exemplo:

```prolog
copa(1958, sweden, brazil, sweden, france, germany_fr, 126, 16, 35, 819810).
```

## Arquivos

```
.
├── data/WorldCups.csv   dataset original
├── etl.py               script Python que gera os fatos
├── regras.pl            regras Prolog (helpers + as 3 perguntas)
├── copas.pl             arquivo final pronto pra rodar no SWISH
└── README.md
```

O `etl.py` lê o CSV, normaliza os nomes (minúsculas, sem acento, sem espaço) e gera o `copas.pl` já com as regras do `regras.pl` anexadas no final. O `copas.pl` está versionado, então só precisa rodar o ETL de novo se mudar o CSV ou o `regras.pl`.

## Como rodar

Pré-requisitos: Python 3.9+ (só pra regerar o `copas.pl`) e um navegador.

Regerar a base (opcional):

```bash
python etl.py
```

Pra testar as queries:

1. Abre o [SWISH](https://swish.swi-prolog.org/).
2. Cria uma célula **Program** e cola o conteúdo de `copas.pl`.
3. Cria uma célula **Query** e roda uma das queries da próxima seção.

## As 3 perguntas

### 1. Quais países mais venceram a Copa do Mundo?

Query:

```prolog
?- ranking_titulos(R).
```

A regra `titulos/2` conta quantas vezes cada país aparece como `Winner` (usando `findall + length`), e `ranking_titulos/1` ordena de forma decrescente com `setof + reverse`. Pra evitar o problema de variável livre no `findall` (mencionado no PDF do projeto), criei o predicado `pais/1` que enumera todo país que aparece em alguma das 5 posições qualitativas da base.

Resultado:

```prolog
R = [5-brazil, 4-italy, 3-germany_fr, 2-uruguay, 2-argentina,
     1-spain, 1-germany, 1-france, 1-england].
```

Brasil pentacampeão, Itália tetra, Alemanha Ocidental tri. Repare que `germany_fr` (Alemanha Ocidental, campeã em 1954/74/90) e `germany` (Alemanha unificada, campeã em 2014) aparecem separados — o CSV original distingue as duas e mantive isso no ETL pra não distorcer o histórico.

### 2. Quais foram as 5 edições com maior média de gols por partida?

Query:

```prolog
?- top5_media_gols(T).
```

A regra `media_gols/2` faz a divisão `Gols / Partidas` pra cada edição. `ranking_media_gols/1` ordena decrescente, e `top5_media_gols/1` fatia os 5 primeiros usando `length + append` (truque comum em Prolog pra pegar prefixo de lista de tamanho fixo).

Resultado:

```prolog
T = [5.384615384615385-1954, 4.666666666666667-1938,
     4.117647058823529-1934, 4.0-1950,
     3.888888888888889-1930].
```

Curioso: as 5 Copas mais "ofensivas" da história em média de gols são todas anteriores a 1960. A Suíça/1954 lidera com 5,38 gols por jogo (140 gols em 26 partidas).

### 3. Quais países foram campeões jogando em casa?

Query:

```prolog
?- ranking_campeao_em_casa(R).
```

A regra-chave usa unificação dupla — a mesma variável `Pais` aparece em duas posições do fato `copa/10`, então o Prolog filtra automaticamente as edições em que `Sede == Campeao`:

```prolog
campeao_em_casa(Pais, Ano) :-
    copa(Ano, Pais, Pais, _, _, _, _, _, _, _).
```

Resultado:

```prolog
R = [1-uruguay, 1-italy, 1-france, 1-england, 1-argentina].
```

Cinco seleções: Uruguai (1930), Itália (1934), Inglaterra (1966), Argentina (1978) e França (1998).

**Observação importante sobre o dataset:** A Alemanha sediou e ganhou a Copa de 1974, mas o CSV original registra a sede como `Germany` e o campeão como `Germany FR`. Depois da normalização viram átomos diferentes (`germany` e `germany_fr`), então essa edição não casa na unificação. É uma inconsistência da fonte, não do código — vale registrar no README pra deixar transparente.

## Notas sobre o ETL

Três pontos do `etl.py` que merecem comentário:

- `to_atom` converte qualquer string num átomo Prolog válido (minúscula, sem acento via `unicodedata.normalize`, sem espaço nem caractere especial). Ex: `Germany FR` → `germany_fr`, `Korea/Japan` → `korea_japan`, `South Africa` → `south_africa`.
- `parse_attendance` lida com o formato europeu do CSV (`1.045.246` → `1045246`), pra deixar o público como inteiro e permitir aritmética.
- Linhas vazias no fim do CSV são ignoradas.

Depois disso o script só concatena o `regras.pl` no final e escreve o `copas.pl`.

## Cuidados que tomei (erros comuns do PDF)

- Constantes em minúscula, variáveis em maiúscula.
- Toda cláusula com ponto final.
- `findall` sempre com a chave de agrupamento amarrada por `pais/1` (nada de variável livre fazendo "group by sem chave").
- Queries ficam só na célula Query do SWISH — no `copas.pl` elas aparecem como comentário no final, fora da Program.
