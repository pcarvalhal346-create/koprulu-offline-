# Alquimix

Jogo **Match-3 com alquimia** para Android, iOS e HTML5, feito em **Defold** e **Lua**.
O jogador é um aprendiz do **Lumi, Rei da Alquimia**, e restaura o equilíbrio do Reino de
Luméria ao longo de **60 níveis** em 3 mundos. Cada combinação feita pelo jogador cria um
**elemento carregado**; elementos carregados fundem-se com elementos diferentes para criar
**10 compostos** (Vapor, Lava, Plasma, Vida, Gelo, Poeira, Tempestade, Obsidiana, Floresta e
Cristal), cada um com um poder próprio. As receitas descobertas ficam no **Livro de Alquimia**.

- Interface e diálogos em português de Portugal (pt-PT).
- Resolução lógica 720×1280, orientação vertical, interface adaptada a qualquer proporção e à área segura.
- Controlos por toque e rato (arrastar ou tocar em duas peças; tocar duas vezes num composto ativa-o).
- Arte, música e efeitos sonoros originais, gerados por código incluído no projeto.
- Sem anúncios, sem compras, sem serviços externos.

> Este diretório é independente do protótipo "Koprulu Offline" que existe na raiz do repositório.

## Estilo visual

Estilo casual "doce": peças brilhantes com volume (efeito gelatina), cenários diurnos com céu,
nuvens e colinas, botões em pílula, HUD com objetivos à esquerda, círculo central de jogadas e
medidor de estrelas à direita, e mapa com caminho de pedras e barra de navegação inferior.
Toda a arte é original (desenhada por código em `tools/art`); segue as convenções do género
Match-3 sem reproduzir peças, personagens, logótipo ou mapa de nenhum jogo existente.

## Abrir no Defold

1. Instala o [editor Defold](https://defold.com/download/) (desenvolvido com a versão estável **1.14.1**).
2. *File → Open Project* e escolhe `alquimix/game.project`.
3. *Project → Build* (Ctrl/Cmd+B) executa o jogo no computador.

Não há dependências externas (nenhuma biblioteca em `[project] dependencies`).

## Testar em HTML5

- No editor: *Project → Build HTML5*, ou
- Na linha de comandos (Java 25 + `bob.jar` da mesma versão do Defold):

```bash
BOB=/caminho/bob.jar tools/build.sh web
python3 -m http.server 8000 --directory dist/web/Alquimix
# abrir http://localhost:8000
```

O canvas ocupa a janela inteira (`html5.scale_mode = stretch`) e a interface adapta-se à proporção.
O som só arranca depois do primeiro toque (regra dos navegadores).

## Builds Android e iOS

- **Android:** *Project → Bundle → Android Application* no editor, ou `BOB=... tools/build.sh android`
  (gera um APK em `dist/android`). Para publicar, cria um *keystore* próprio e indica-o no diálogo de bundle
  (ou com `--keystore`/`--keystore-pass` no bob). Pacote: `com.alquimix.game`.
- **iOS:** *Project → Bundle → iOS Application* num Mac com Xcode, certificado de desenvolvimento e
  *provisioning profile*. Bundle id: `com.alquimix.game`.
- Ícones de aplicação: está gerado um ícone original em `assets/icons/icon_512.png`; os tamanhos
  específicos de cada loja ainda têm de ser exportados e ligados em `game.project` (*Android/iOS → Icons*).

## Organização do código

```
alquimix/
├── game.project, input/game.input_binding
├── main/            main.collection, game.go (GUI), audio.go (componentes de som), game.gui(_script)
├── scripts/         lógica pura (sem GUI) e serviços
│   ├── board.lua         estado do tabuleiro (camadas piece / blocker / cover / corrupt / terreno)
│   ├── match.lua         deteção de combinações e grupos em T/L
│   ├── gravity.lua       queda, reabastecimento, portais e deslizamento diagonal
│   ├── alchemy.lua       regras de fusão e áreas dos poderes
│   ├── obstacles.lua     rochas, gelo, raízes, corrupção
│   ├── terrain.lua       tapetes rolantes e baralhar
│   ├── moves.lua         jogadas válidas
│   ├── game_rules.lua    turnos, fusões, poderes, cascatas, vitória/derrota -> lista de eventos
│   ├── objectives.lua, progression.lua, save_manager.lua, level_manager.lua, level_validator.lua
│   ├── tutorial_manager.lua, lumi.lua, localization.lua, rng.lua, autoplay.lua
│   └── animations.lua (fila de animações), effects.lua (partículas), audio_manager.lua
├── gui/             ecrãs e componentes visuais (screen_manager, board_view, game_screen, world_map,
│                    alchemy_book, main_menu, tutorial_view, victory_view, settings_view, dialog, lumi_view…)
├── levels/          world_01.lua, world_02.lua, world_03.lua (60 níveis em dados)
├── data/            elements, recipes, tutorial_data, obstacle_patterns, board_presets, lumi_rig (gerado)
├── assets/          PNG, atlases, fontes, áudio, ícone
├── tests/           testes automáticos + simulador de partidas
├── tools/           geradores de arte (Node) e áudio (Python), scripts de build/testes
└── docs/            alterações aos níveis, equilíbrio, estado
```

**Arquitetura:** a lógica (`scripts/`) não conhece nós GUI. Cada ação do jogador
(`Game:try_swap`, `Game:activate`) altera tabelas Lua e devolve uma lista de eventos
(`swap`, `fusion`, `discovery`, `match`, `charge`, `remove`, `power`, `gravity`, `cascade`,
`clear_obstacle`, `conveyor`, `corruption_spread`, `shuffle`, `objective_progress`, `victory`, …).
`gui/board_view.lua` reproduz esses eventos numa fila ordenada (`scripts/animations.lua`); enquanto a
fila está ocupada o tabuleiro ignora toques. No fim de cada ação a vista reconcilia-se com o estado lógico.

## Regras implementadas (resumo)

- Troca adjacente; só é aceite se criar uma combinação ou uma fusão. Trocas inválidas voltam atrás e não gastam jogadas.
- Combinação manual (3, 4, 5+, T/L como um único grupo): as peças são eliminadas e a peça movida fica **carregada**.
  Combinações automáticas (cascatas) nunca criam peças carregadas. Match-4/5/cruz dão bónus.
- Fusões: carregado + elemento diferente, carregado + carregado, composto + elemento (receita existente,
  qualquer ordem). Composto surge no destino; a origem é preenchida pela gravidade; gasta 1 jogada.
- Compostos: tocar seleciona (realça parceiros compatíveis), tocar outra vez ativa (gasta 1 jogada).
  Compostos são imunes a poderes de outros compostos (não se perdem por acidente).
- Rochas só se partem com poderes (Lava causa 2 de dano; Obsidiana destrói todas).
  Gelo, raízes e corrupção prendem a peça; saem com combinações adjacentes ou poderes; a camada superior absorve cada golpe.
- Tapetes: a linha desloca-se uma casa a cada 3 jogadas válidas. Portais: transportam uma peça para a saída livre, uma vez por peça em cada resolução.
- Corrupção: espalha-se para uma célula vizinha elegível a cada 3 jogadas, com limite por nível.
- Sem jogadas: baralhar (compostos, obstáculos e peças presas ficam no lugar). Cascatas limitadas a 50 passos.
- Estrelas: 1 = vencer; 2 = ≥20% das jogadas restantes; 3 = ≥40% (limiares arredondados para cima). As estrelas nunca descem.

## Criar novos níveis

Acrescenta uma tabela a `levels/world_0X.lua` (ou um novo ficheiro e uma linha `require` em
`scripts/level_manager.lua`):

```lua
{
	id = 61, world = 3, name = "Novo Desafio", moves = 30, seed = 6161,
	elements = { "fire", "water", "earth", "air" }, weights = { fire = 12 },
	goals = { { type = "activate", id = "storm", count = 2 }, { type = "clear", id = "rock", count = 6 } },
	layout = {           -- . normal  # vazio  r/R rocha 1/2  i/I gelo 1/2  v raízes  c corrupção
		"........", "........", "........", "rr.rr.rr",
		"........", "........", "........", "........",
	},
	layers = { { pattern = "corners", tile = "i" } },          -- padrões de data/obstacle_patterns.lua
	terrain = {
		portals = { { from = { x = 1, y = 3 }, to = { x = 1, y = 5 } } },
		conveyors = { { axis = "row", index = 2, dir = 1 } },
		corruption = { period = 3, limit = 5, max_cells = 12 },
	},
	tutorial = nil, board_preset = nil,
}
```

Corre `luajit tests/run_tests.lua`: o validador recusa elementos/obstáculos inexistentes, objetivos
impossíveis, tapetes sobre células imóveis, células que a gravidade nunca consegue encher, etc.
Depois `luajit tests/simulate.lua 4 61 61` dá uma estimativa de dificuldade.
(O mapa mostra 60 níveis; para mais níveis ajusta `progression.TOTAL_LEVELS` e `level_manager.WORLDS`.)

## Adicionar receitas e elementos

1. `data/recipes.lua`: nova entrada em `M.recipes` (chave ordenada alfabeticamente, `a|b`) e em `M.list`.
2. `data/elements.lua`: informação do resultado (`compound = true`, `tier`, `power`, cor, sprite).
3. `scripts/game_rules.lua` (`Game:activate`) e `scripts/alchemy.lua`: comportamento do poder, se for novo.
4. `scripts/localization.lua`: `el.<id>` e `power.<id>`.
5. Arte: função em `tools/art/pieces.mjs` e `node generate.mjs` (o atlas é regenerado).
Os testes verificam todas as receitas e textos.

## Substituir gráficos e sons

Toda a arte é desenhada em SVG por `tools/art/*.mjs` e convertida para PNG:

```bash
cd tools/art && npm install && node generate.mjs   # PNG + .atlas + data/lumi_rig.lua
python3 tools/audio/generate_audio.py              # OGG (precisa de numpy e ffmpeg)
```

Para usar arte feita à mão basta substituir o PNG com o mesmo nome em `assets/...` (o atlas usa o nome
do ficheiro como id). O Lumi é montada a partir de partes (`assets/lumi/*.png`) e de
`data/lumi_rig.lua` (posição de cada parte e articulações); ao trocar a arte do Lumi mantém as partes
alinhadas na mesma tela de 400×520 ou atualiza o rig.

## Alterar os diálogos do Lumi

Todos os textos estão em `scripts/localization.lua` (chaves `lumi.*`, `tut.*`, `tip.*`, `story.*`).
A escolha de falas (com rotação para não repetir) está em `scripts/lumi.lua`; os passos dos tutoriais
em `data/tutorial_data.lua`.

## Testes

```bash
luajit tests/run_tests.lua          # 60 testes (LuaJIT 2.1 ou Lua 5.1)
luajit tests/simulate.lua 4         # bot joga os 60 níveis com 4 seeds cada
luacheck . main/game.gui_script     # análise estática (configuração em .luacheckrc)
```

Opções de desenvolvimento (secção `[elemental]` do `game.project`, ou um ficheiro passado ao bob com
`--settings`): `unlock_all = 1`, `start_level = N`, `autoplay = 1` (o bot joga dentro do motor).

## Recursos e licenças

| Recurso | Origem | Licença |
|---|---|---|
| Arte (peças, compostos, obstáculos, UI, Lumi, cenários, efeitos, ícone) | Original, gerada por `tools/art/*.mjs` | Do projeto |
| Música (2 loops) e 27 efeitos sonoros | Originais, sintetizados por `tools/audio/generate_audio.py` | Do projeto |
| Fonte Fredoka (SemiBold) | The Fredoka Project Authors, via pacote npm `@fontsource/fredoka` | SIL OFL 1.1 (`assets/fonts/OFL-Fredoka.txt`) |
| Fonte Nunito (ExtraBold) | The Nunito Project Authors, via `@fontsource/nunito` | SIL OFL 1.1 (`assets/fonts/OFL-Nunito.txt`) |
| Ferramentas de geração | `@resvg/resvg-js`, `pngjs` (npm), numpy, ffmpeg | MPL-2.0 / MIT / BSD / LGPL (não incluídas no jogo) |

Nenhuma imagem, som ou personagem de terceiros é usado. A inspiração em jogos Match-3 limita-se às
convenções gerais do género.

Mais detalhes: [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md), [`docs/LEVEL_CHANGES.md`](docs/LEVEL_CHANGES.md),
[`docs/BALANCE.md`](docs/BALANCE.md).
