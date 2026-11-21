# Alterações à tabela de níveis e interpretações de regras

A tabela de design dos 60 níveis foi implementada nível a nível. **Jogadas e objetivos são exatamente
os da tabela** (nenhum valor foi alterado). As mudanças abaixo são técnicas: layouts, obstáculos
adicionais e interpretação de regras que a tabela não especificava.

## Correções técnicas

| Nível | Alteração | Motivo |
|---|---|---|
| 5 | Rochas em `..r.r...` (linha 7) + cantos inferiores, em vez de 3 rochas seguidas | A célula por baixo de três rochas seguidas nunca podia ser reabastecida pela gravidade |
| 18 | Padrão `middle_bar` passou a `x.x..x.x` | Idem (células presas por baixo de barras de 3 rochas) |
| 22 | Rochas `r.R..R.r` / `RrR..RrR` | Idem; continuam a existir 10 rochas para o objetivo de 7 |
| 40 | Gelo `..I..I..` + `I..ii..I` | A versão inicial só tinha 6 camadas de gelo para um objetivo de 8 (impossível) |
| 41, 42, 43, 46, 48, 50, 57 | Barras de rochas com aberturas (`rr.rr.rr`, `rR.rr.Rr`) e portais nas colunas das extremidades | Com barras contínuas, várias células abaixo das rochas nunca recebiam peças; agora cada célula tem caminho (gravidade, diagonal ou portal) |
| 60 | Barra `rr.RR.rr` | Idem |

O validador (`scripts/level_validator.lua`) trata estas situações como **erro**: células que a
gravidade nunca enche, objetivos `clear` com menos obstáculos do que o pedido, compostos que não se
podem produzir com os elementos do nível, tapetes que atravessam células imóveis, etc.

## Obstáculos e terreno acrescentados

A tabela indica apenas a mecânica principal de cada nível. Para dar identidade a cada nível foram
acrescentados padrões de obstáculos que **não fazem parte dos objetivos**:

- Rochas decorativas: 8, 16, 18, 27, 33, 34, 37 (obstruem e obrigam a usar diagonais/poderes).
- Nível 19: gelo em diagonal sem objetivo de gelo (obriga a libertar peças para criar Tempestades).
- Mundo 3: corrupção também nos níveis 54, 56–59 ("combinações de mecânicas anteriores").
- Níveis 6 e 12 usam cantos vazios (`cut_corners`) para um tabuleiro em forma de octógono.

## Formas de tabuleiro

30 níveis (sem tutorial) receberam uma silhueta com o campo `shape` (`shape_hex`, `shape_cross`,
`shape_funnel`, `shape_notches`, `shape_crown`, em `data/obstacle_patterns.lua`). A silhueta só
transforma em vazio as células normais, nunca obstáculos, e cada nível só ficou com uma forma que
passa no validador (objetivos alcançáveis e todas as células reabastecíveis). Jogadas e objetivos
não mudaram.

## Interpretações de regras

- **Peças carregadas participam em combinações** como o seu elemento (se forem eliminadas por uma combinação contam para `collect`).
- **Grupos T/L/cruz** são um único grupo; a peça movida recebe a carga. Se as duas peças trocadas formarem grupos, ambas ficam carregadas.
- `charge` conta apenas peças que passam de normais a carregadas.
- **Peças presas** (gelo, raízes, corrupção) podem fazer parte de combinações; a camada absorve o golpe e a peça fica.
- Danos por **combinação adjacente**: afetam gelo, raízes e corrupção nas 4 células vizinhas de cada peça combinada (incluindo a que fica carregada), no máximo uma vez por célula e por passo. As rochas não sofrem dano de combinações (regra da especificação: "só são destruídas por efeitos").
- **Poderes**: a camada superior de cada célula absorve o golpe (rocha > gelo/raízes > corrupção > peça). Os compostos são imunes a poderes de outros compostos.
- `clear frost` conta **camadas** removidas; `clear vine`/`clear rock`/`clear corruption` contam obstáculos removidos.
- **Gelo (composto)** atinge um bloco 2×2 (a própria célula, direita, baixo e diagonal; deslocado para dentro do tabuleiro nas margens).
- **Vida** transforma as peças normais vizinhas (até 4) e **Floresta** até 8 peças normais escolhidas com o gerador do nível. As transformações só são resolvidas na fase de resolução seguinte.
- **Tapetes**: deslocação cíclica de uma casa a cada 3 jogadas válidas; linhas e colunas suportadas.
- **Corrupção**: bloqueia a peça como o gelo; espalha-se para uma célula vizinha com peça normal, sem
  cobertura, fora de tapetes e portais, a cada `period` jogadas, até `limit` vezes e `max_cells` células.
  O validador exige que a corrupção inicial já chegue para o objetivo.
- **Reabastecimento**: novas peças que completariam logo uma combinação são trocadas com probabilidade
  `cascade_damping` (0,92 por omissão, configurável por nível). As cascatas causadas por peças que já
  estavam no tabuleiro não são alteradas.
