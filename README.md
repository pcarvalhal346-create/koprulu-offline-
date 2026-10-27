# Koprulu Offline — protótipo jogável (PWA para iPhone)

**Jogo de estratégia espacial single-player**, com a economia e as missões de navegador de um OGame clássico e uma camada temática inspirada em StarCraft II. **Não é um produto da Blizzard, da Gameforge, nem uma conversão do XGProyect-FMJ.** O código e os ícones são criados para este protótipo; os nomes e personagens de StarCraft são propriedade dos seus titulares. Destina-se a experimentação privada, não a distribuição comercial com essas marcas.

## O que funciona

- **Escolha entre Terran, Zerg e Protoss** antes de iniciar a campanha.
- **3 líderes por raça** (9 no total); escolhes 1 inicial e podes recrutar os outros 2 com recursos.
- Alternar líder ativo; bónus passivos reais nas fórmulas (ataque, produção, defesa ou duração de filas), **poderes especiais** com recarga de 30 minutos.
- 20 bots, distribuídos entre as três raças, com líderes próprios e diferentes estilos de desenvolvimento.
- 8 edifícios, 6 tecnologias, 6 tipos de frotas com designações por raça, 2 defesas, energia e 3 recursos.
- Filas de produção, reconhecimento por sondas, ataque, combate automático simplificado, saque e relatórios.
- Interface responsiva para iPhone, instalação PWA, cache de ficheiros estáticos, simulação de tempo decorrido com a aplicação fechada.
- Gravação em IndexedDB (fallback localStorage), exportação/importação de saves JSON e migração de saves da versão 1.
- Botão **Opções → Simular +1 hora** para experimentar sem esperar.

**Limites:** é um protótipo com um planeta controlado pelo jogador, sem multiplayer, heróis em combate tático em tempo real, terreno de batalha, colonização, alianças ou campanhas. As fórmulas de OGame/StarCraft II **não são reproduzidas exatamente**. A IA é simples, com turnos simulados ao reabrir a aplicação; não corre em segundo plano quando o iPhone está bloqueado.

## Publicar e instalar apenas com o iPhone, sem VPS

1. Descomprime `koprulu-offline.zip` em **Ficheiros**.
2. Abre <https://github.com/new> e cria um repositório público (por exemplo, `koprulu-offline`). Não envies dados privados para o repositório.
3. Em **Add file → Upload files**, carrega **os ficheiros descomprimidos**, mantendo `index.html`, `app.js`, `engine.mjs`, `styles.css`, `sw.js`, `manifest.webmanifest` e a pasta `icons/` nas posições originais. Não carregues apenas o ZIP. Se necessário pede a versão para computador no Safari.
4. Em **Settings → Pages**, escolhe **Deploy from a branch**, branch `main` e pasta `/(root)`.
5. Abre no Safari o endereço mostrado pelo GitHub Pages (tipicamente `https://UTILIZADOR.github.io/koprulu-offline/`).
6. Usa **Partilhar → Adicionar ao ecrã principal → Abrir como aplicação**. Abre o jogo uma vez com rede e testa a abertura em modo avião.
7. A partir do ecrã inicial escolhe a raça e o primeiro líder, depois **Iniciar campanha**.

O GitHub Pages **aloja apenas os ficheiros estáticos**. A simulação e o save são executados no teu dispositivo. Não há VPS nem serviço de jogo 24 horas por dia. A instalação/atualização inicial requer internet.

**Atenção:** na PWA instalada, os dados locais podem ser apagados se removeres a app ou limpares o armazenamento. Faz cópias em **Opções → Exportar progresso**, preferencialmente para iCloud Drive.

## Usar com Codex

Cria/importa o repositório no GitHub e seleciona-o num ambiente Codex. Instrução inicial sugerida:

> Trabalha sobre este protótipo offline (HTML, CSS, JavaScript, PWA). Mantém a escolha Terran/Zerg/Protoss, 9 líderes, 20 bots, jogo offline e progresso local. Executa `node --test test.mjs`. Analisa o motor e a interface antes de modificar. Não introduzas backend, serviços cloud para o jogo ou materiais gráficos protegidos de terceiros. Faz melhorias pequenas e testáveis, começando por balanceamento e sistema de combate. Apresenta o trabalho num pull request.

## Testes de motor

Node.js 20 ou superior, sem `npm install`:

```bash
node --test test.mjs
```

Para testes num navegador de computador usa um **servidor estático** (ficheiros ES modules requerem servidor web, não abras `index.html` via `file://`):

```bash
python3 -m http.server 8000
```

Abre `http://localhost:8000`. A PWA requer HTTPS em publicação.

## Ficheiros

- `index.html` estrutura HTML; `styles.css` interface e temas de raça.
- `engine.mjs` economia, líderes, combate, bots e tempo; `app.js` interface e salvamento.
- `sw.js` cache offline; `manifest.webmanifest` manifesto PWA; `icons/` ícones originais.
- `test.mjs` testes automáticos; `.nojekyll` para GitHub Pages.

## Avisos legais

Protótipo experimental de fã não comercial, não aprovado pela Blizzard Entertainment. *StarCraft*, *Terran*, *Zerg*, *Protoss* e os nomes das personagens são marcas/obras dos respetivos proprietários. O projeto **não inclui assets oficiais**. Para distribuir ou comercializar uma versão pública, substitui todos esses elementos por universo, facções, personagens, designações e materiais originais e verifica os direitos aplicáveis.
