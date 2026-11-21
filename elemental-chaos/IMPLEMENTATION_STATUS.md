# Estado da implementação

Atualizado no fim da sessão de desenvolvimento inicial. "Verificado no motor" significa executado no
runtime Defold 1.14.1 (build HTML5/wasm com `bob.jar`) num Chromium sem ecrã (renderização por software).

## Módulos

| Área | Estado | Verificação |
|---|---|---|
| Projeto Defold (`game.project`, coleção, GUI, input, fontes, atlases, sons) | Feito | `bob.jar` build debug e release sem erros; bundle HTML5 e APK Android gerados |
| Tabuleiro, matches (3/4/5, T/L), trocas inválidas, gravidade, reabastecimento, cascatas | Feito | Testes 1–6, 12–14; motor |
| Peças carregadas, 10 receitas, fusões, compostos, 10 poderes, escolha do Cristal | Feito | Testes 7–11 (todas as receitas e poderes); motor (fusão, descoberta, poderes) |
| Obstáculos: rocha 1/2, gelo 1/2, raízes, corrupção (espalhamento com limite) | Feito | Testes 16, 19; motor (níveis 20, 44, 51) |
| Tapetes rolantes, portais, baralhar sem jogadas | Feito | Testes 15, 17, 18; motor (31, 41) |
| Objetivos (collect, charge, create, activate, clear), estrelas, vitória/derrota | Feito | Testes 20–23; motor (vitória nos níveis 3/20/51, derrota no 25) |
| 60 níveis individuais + padrões de obstáculos + presets de tutorial | Feito | Validação estrutural 60/60; simulação automática (ver `docs/BALANCE.md`) |
| Validador de níveis | Feito | Teste 25 + testes de definições inválidas |
| Simulador/bot de partidas | Feito | `tests/simulate.lua`; também joga dentro do motor (`autoplay = 1`) |
| Gravação (sys.save/sys.load), valores por omissão, migração v0→v1→v2 | Feito | Teste 24 (backend em memória). No motor só foi exercitado o caminho de escrita em HTML5 |
| Tutoriais guiados (16 tutoriais), veu com abertura, mão animada, bloqueio de ações, saltar, persistência, repetir | Feito | Teste que executa todos os passos guiados; motor (níveis 1, 3, 31, 41, 51) |
| Dicas: realce após 7 s parado; dica do Lumi após 4 jogadas sem progresso | Feito | Motor (dica de rochas no nível 20) |
| Lumi: rig por partes, 6 olhos, 6 bocas, 8 estados, piscar, falar | Feito | Motor (menu, diálogos, vitória, derrota, descoberta) |
| Menu principal, introdução (saltável), mapa com 60 níveis (nós reutilizados), popup de nível | Feito | Motor |
| Livro de Alquimia (silhuetas, contador, "Novo!", detalhe), descoberta com carta | Feito | Motor |
| Pausa, Definições (música, sons, reduzir animações, repetir tutoriais) | Feito | Motor |
| Final de mundo (20, 40) e da campanha (60) com sequência narrativa | Feito | Motor (nível 20); 40/60 usam o mesmo código |
| Transição de novo mundo no mapa | Feito | Código; não capturado em ecrã |
| Partículas (pool de 160 nós), efeitos por poder, confetes, textos de combo | Feito | Motor |
| Áudio: 27 efeitos + 2 músicas originais; música/sons desligáveis | Feito | Ficheiros gerados e incluídos; **não foi possível ouvir** o resultado neste ambiente |
| Áreas seguras (notch) | Feito | Usa `window.get_safe_area()`; testado apenas sem notch |
| Proporções de ecrã | Feito | Motor: 9:16, 9:20 e 3:4 |

## Testes executados (resultado)

- `luajit tests/run_tests.lua`: **60 testes, 0 falhas** (cobre os 25 pontos pedidos).
- `luacheck`: 0 avisos, 0 erros.
- `tests/simulate.lua 4`: 58/60 níveis com 4/4 vitórias do bot; nível 25 (2/4) e 48 (3/4).
- Build `bob.jar` 1.14.1 (Java 25): debug e release, HTML5 e Android APK (arm64) sem erros.
- Execução no motor (HTML5, Chromium headless): menu → introdução → mapa → popup → nível 1 com tutorial e
  jogada guiada por arrastamento; autoplay completo dos níveis 3, 20, 31, 41, 51 (vitória) e 25 (derrota);
  descoberta, livro, definições, pausa; 3 proporções de ecrã.

## Por verificar / limitações conhecidas

- **Não foi testado em dispositivos Android/iOS reais**, nem medido o FPS em telemóveis. O APK foi gerado
  mas não instalado. O bundle iOS exige macOS/Xcode.
- O **editor Defold** não foi aberto (só a ferramenta de linha de comandos `bob.jar`, que usa o mesmo pipeline).
- **Equilíbrio**: sem testes com jogadores reais; o bot indica que a maioria dos níveis tem muita folga
  (ver `docs/BALANCE.md`). Níveis 1–6 com 3 elementos geram cascatas longas.
- **Música**: composição procedimental simples (dois loops); funcional mas não ao nível de uma banda sonora
  profissional — recomendada substituição por música composta.
- **Arte**: vetorial original de estilo cartoon, gerada por código; adequada para o jogo mas não foi feita por
  um ilustrador. Ícones de aplicação por plataforma ainda não configurados em `game.project`.
- Lumi é animada por composição de partes (sem frames desenhados à mão).
- Em HTML5 o áudio só começa após a primeira interação (política dos navegadores).
- Redimensionar a janela durante uma animação do tabuleiro só reconstrói a interface na próxima ocasião estável.

## Próximo passo recomendado

1. Sessões de jogo com pessoas e ajuste de `moves`/`weights` (sugestões em `docs/BALANCE.md`).
2. Teste em 2–3 telemóveis Android e 1 iPhone (desempenho, notch, toque).
3. Ícones de loja, ecrã de arranque e assinatura de release.
4. Substituir música e, se possível, rever a arte com um ilustrador usando as especificações em `tools/art`.
