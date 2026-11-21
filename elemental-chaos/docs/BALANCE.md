# Equilíbrio dos níveis

Três níveis de verificação, que **não devem ser confundidos**:

1. **Validação estrutural** (`scripts/level_validator.lua`, executada por `tests/run_tests.lua`):
   todos os 60 níveis passam. Garante dados válidos, objetivos teoricamente alcançáveis, tabuleiro
   inicial sem combinações e com jogadas, células sempre reabastecíveis e um orçamento mínimo de jogadas.
2. **Simulação automática** (`tests/simulate.lua`, bot em `scripts/autoplay.lua`): um jogador ganancioso
   que avalia todas as ações possíveis com um passo de antecipação e conhece os objetivos (sem ver as
   peças futuras). Resultados abaixo (4 seeds por nível).
3. **Testes reais de jogabilidade com pessoas**: **ainda não foram feitos.** As jogadas da tabela de design
   foram mantidas sem alterações.

## Leitura dos resultados

- O bot vence 58 dos 60 níveis em todas as seeds e termina quase sempre com muitas jogadas de sobra.
  O bot é mais forte do que um jogador casual em cálculo (avalia ~100 ações por jogada), mas mais fraco em
  planeamento; por isso estes números indicam **folga**, não dificuldade real.
- Níveis mais exigentes para o bot: **25** (Ativar 3 Lavas + 9 rochas, 2/4) e **48** (12 rochas + 3 Lavas, 3/4).
- Os níveis 1–6 usam só 3 elementos (como pede o design); com 3 cores as peças que caem formam muitas
  cascatas, por isso o nível 1 pode ser concluído em poucas jogadas. É intencional para a introdução, mas
  é o primeiro ponto a rever com jogadores reais.
- Sugestões para a próxima iteração de equilíbrio (não aplicadas): reduzir jogadas em ~15–25% nos
  níveis com mais de 20 jogadas restantes; aumentar `weights` dos elementos não necessários para diluir
  fusões; subir a resistência das rochas (`R`) nos níveis 30–40.

Parâmetros expostos para equilíbrio: `moves`, `weights`, `cascade_damping`, `layout`/`layers` (incluindo
resistência das rochas `r`/`R` e camadas de gelo `i`/`I`), `terrain.corruption.period/limit/max_cells`,
`terrain.conveyor_period`, `min_moves` (jogadas mínimas no tabuleiro inicial), `seed`.

## Resultados da simulação (4 seeds)

| Nível | Jogadas | Vitórias do bot | Jogadas restantes (média) | Estrelas (média) | Progresso médio |
|---|---|---|---|---|---|
| 1 | 16 | 4/4 | 14.5 | 3.0 | 100% |
| 2 | 15 | 4/4 | 13.0 | 3.0 | 100% |
| 3 | 17 | 4/4 | 16.0 | 3.0 | 100% |
| 4 | 18 | 4/4 | 14.0 | 3.0 | 100% |
| 5 | 20 | 4/4 | 6.3 | 2.3 | 100% |
| 6 | 17 | 4/4 | 12.8 | 3.0 | 100% |
| 7 | 18 | 4/4 | 15.5 | 3.0 | 100% |
| 8 | 19 | 4/4 | 13.0 | 3.0 | 100% |
| 9 | 21 | 4/4 | 19.0 | 3.0 | 100% |
| 10 | 24 | 4/4 | 15.8 | 3.0 | 100% |
| 11 | 23 | 4/4 | 20.3 | 3.0 | 100% |
| 12 | 22 | 4/4 | 16.0 | 3.0 | 100% |
| 13 | 24 | 4/4 | 17.8 | 3.0 | 100% |
| 14 | 25 | 4/4 | 19.5 | 3.0 | 100% |
| 15 | 25 | 4/4 | 23.0 | 3.0 | 100% |
| 16 | 24 | 4/4 | 19.5 | 3.0 | 100% |
| 17 | 26 | 4/4 | 23.5 | 3.0 | 100% |
| 18 | 26 | 4/4 | 17.3 | 3.0 | 100% |
| 19 | 27 | 4/4 | 17.8 | 3.0 | 100% |
| 20 | 30 | 4/4 | 12.0 | 2.5 | 100% |
| 21 | 25 | 4/4 | 6.0 | 1.8 | 100% |
| 22 | 26 | 4/4 | 17.0 | 3.0 | 100% |
| 23 | 25 | 4/4 | 19.3 | 3.0 | 100% |
| 24 | 26 | 4/4 | 12.8 | 2.5 | 100% |
| 25 | 27 | 2/4 | 7.0 | 1.5 | 94% |
| 26 | 27 | 4/4 | 17.8 | 3.0 | 100% |
| 27 | 27 | 4/4 | 15.3 | 3.0 | 100% |
| 28 | 28 | 4/4 | 19.8 | 3.0 | 100% |
| 29 | 28 | 4/4 | 16.8 | 2.8 | 100% |
| 30 | 30 | 4/4 | 15.3 | 2.8 | 100% |
| 31 | 27 | 4/4 | 18.0 | 3.0 | 100% |
| 32 | 28 | 4/4 | 18.8 | 3.0 | 100% |
| 33 | 28 | 4/4 | 19.8 | 3.0 | 100% |
| 34 | 29 | 4/4 | 19.0 | 3.0 | 100% |
| 35 | 30 | 4/4 | 24.0 | 3.0 | 100% |
| 36 | 30 | 4/4 | 21.0 | 3.0 | 100% |
| 37 | 30 | 4/4 | 16.8 | 2.8 | 100% |
| 38 | 31 | 4/4 | 18.5 | 3.0 | 100% |
| 39 | 32 | 4/4 | 23.8 | 3.0 | 100% |
| 40 | 33 | 4/4 | 7.0 | 1.8 | 100% |
| 41 | 28 | 4/4 | 20.8 | 3.0 | 100% |
| 42 | 29 | 4/4 | 19.3 | 3.0 | 100% |
| 43 | 29 | 4/4 | 16.3 | 2.5 | 100% |
| 44 | 30 | 4/4 | 18.0 | 3.0 | 100% |
| 45 | 30 | 4/4 | 17.3 | 3.0 | 100% |
| 46 | 31 | 4/4 | 13.3 | 2.5 | 100% |
| 47 | 32 | 4/4 | 18.3 | 3.0 | 100% |
| 48 | 32 | 3/4 | 5.3 | 1.3 | 95% |
| 49 | 32 | 4/4 | 22.8 | 3.0 | 100% |
| 50 | 34 | 4/4 | 23.3 | 3.0 | 100% |
| 51 | 29 | 4/4 | 27.5 | 3.0 | 100% |
| 52 | 30 | 4/4 | 21.5 | 3.0 | 100% |
| 53 | 31 | 4/4 | 16.0 | 2.8 | 100% |
| 54 | 32 | 4/4 | 22.3 | 3.0 | 100% |
| 55 | 34 | 4/4 | 23.8 | 3.0 | 100% |
| 56 | 35 | 4/4 | 21.3 | 3.0 | 100% |
| 57 | 35 | 4/4 | 27.8 | 3.0 | 100% |
| 58 | 36 | 4/4 | 28.5 | 3.0 | 100% |
| 59 | 36 | 4/4 | 11.5 | 2.3 | 100% |
| 60 | 40 | 4/4 | 19.3 | 3.0 | 100% |

Reproduzir: `luajit tests/simulate.lua 4` (≈2 minutos). Resultado bruto em `docs/simulation_results.txt`.
