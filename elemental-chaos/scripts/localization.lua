-- All player-facing text (pt-PT). Use L("key", { var = value }) -> string.
-- Placeholders: {name}. Missing keys return the key itself so they are easy to spot.
local M = {}

M.language = "pt-PT"

M.strings = {
	-- --------------------------------------------------------------- menus
	["game.title"] = "Elemental Chaos",
	["menu.play"] = "Jogar",
	["menu.book"] = "Livro de Alquimia",
	["menu.settings"] = "Definições",
	["menu.subtitle"] = "Restaura o equilíbrio de Luméria",
	["common.continue"] = "Continuar",
	["common.close"] = "Fechar",
	["common.back"] = "Voltar",
	["common.skip"] = "Saltar",
	["common.tap_continue"] = "Toca para continuar",
	["common.on"] = "Ligado",
	["common.off"] = "Desligado",
	["map.title"] = "Mapa de Luméria",
	["map.stars"] = "{n} / 180",
	["map.locked_world"] = "Completa o nível {n} para desbloquear",
	["map.new_world"] = "Novo mundo desbloqueado!",
	["level.label"] = "Nível {n}",
	["level.moves"] = "Jogadas",
	["level.score"] = "Pontos",
	["level.goals"] = "Objetivos",
	["level.start"] = "Começar",
	["level.best"] = "Recorde: {n}",
	["hud.tap_again"] = "Toca novamente para ativar",
	["hud.select_partner"] = "Arrasta para um elemento compatível ou toca para ativar",
	["hud.charged"] = "{name} carregado: arrasta-o para um elemento diferente para o fundir",
	["hud.shuffle"] = "Sem jogadas! A misturar os elementos...",
	["hud.locked"] = "Esta peça está presa!",
	["hud.choose_element"] = "Escolhe o elemento a eliminar",
	["pause.title"] = "Pausa",
	["pause.resume"] = "Continuar",
	["pause.restart"] = "Reiniciar",
	["pause.settings"] = "Definições",
	["pause.map"] = "Voltar ao mapa",
	["settings.title"] = "Definições",
	["settings.music"] = "Música",
	["settings.sfx"] = "Efeitos sonoros",
	["settings.reduced"] = "Reduzir animações",
	["settings.tutorials"] = "Repetir tutoriais",
	["settings.tutorials_done"] = "Os tutoriais voltarão a aparecer!",
	["settings.reset"] = "Repor",
	["victory.title"] = "Vitória!",
	["victory.next"] = "Próximo nível",
	["victory.replay"] = "Repetir",
	["victory.map"] = "Mapa",
	["victory.score"] = "Pontuação",
	["victory.bonus"] = "Bónus de jogadas: +{n}",
	["victory.new_best"] = "Novo recorde!",
	["defeat.title"] = "Sem jogadas",
	["defeat.retry"] = "Tentar novamente",
	["defeat.map"] = "Mapa",
	["defeat.missing"] = "Ficou por fazer:",
	["book.title"] = "Livro de Alquimia",
	["book.count"] = "Receitas descobertas: {n}/{total}",
	["book.unknown"] = "Reação desconhecida",
	["book.unknown_hint"] = "Continua a experimentar fusões para revelar este segredo.",
	["book.new"] = "Novo!",
	["book.tier1"] = "Reações de primeiro nível",
	["book.tier2"] = "Reações avançadas",
	["book.power"] = "Poder",
	["book.discovered_in"] = "Descoberta n.º {n} · nível {level}",
	["discovery.title"] = "Nova descoberta!",
	["discovery.recipe"] = "{a} + {b}",
	["combo.2"] = "Combo!",
	["combo.3"] = "Fantástico!",
	["combo.4"] = "Alquimia Perfeita!",
	["combo.5"] = "Caos Elemental!",
	["match.line4"] = "Ótimo!",
	["match.line5"] = "Espetacular!",
	["match.cross"] = "Brilhante!",

	-- ------------------------------------------------------------ objectives
	["goal.collect"] = "Recolhe {n} {name}",
	["goal.charge"] = "Cria {n} elementos carregados",
	["goal.create"] = "Cria {n} {name}",
	["goal.activate"] = "Ativa {n} {name}",
	["goal.clear.rock"] = "Destrói {n} rochas",
	["goal.clear.frost"] = "Remove {n} camadas de gelo",
	["goal.clear.vine"] = "Remove {n} raízes",
	["goal.clear.corruption"] = "Purifica {n} células corrompidas",

	-- -------------------------------------------------------------- elements
	["el.fire"] = "Fogo", ["el.water"] = "Água", ["el.earth"] = "Terra", ["el.air"] = "Ar",
	["el.steam"] = "Vapor", ["el.lava"] = "Lava", ["el.plasma"] = "Plasma", ["el.life"] = "Vida",
	["el.ice"] = "Gelo", ["el.dust"] = "Poeira", ["el.storm"] = "Tempestade", ["el.obsidian"] = "Obsidiana",
	["el.forest"] = "Floresta", ["el.crystal"] = "Cristal",
	["power.steam"] = "Elimina uma coluna inteira com uma coluna de vapor luminoso.",
	["power.lava"] = "Explode numa área 3×3. Causa dano duplo às rochas.",
	["power.plasma"] = "Dispara um raio que elimina uma linha inteira.",
	["power.life"] = "Faz crescer raízes: transforma até 4 peças vizinhas em Terra.",
	["power.ice"] = "Congela e estilhaça uma área 2×2, removendo camadas de gelo.",
	["power.dust"] = "Uma onda de areia causa 1 de dano a todos os obstáculos do tabuleiro.",
	["power.storm"] = "Relâmpagos eliminam a linha e a coluna do composto.",
	["power.obsidian"] = "Energia negra que destrói todas as rochas, mesmo as resistentes.",
	["power.forest"] = "Transforma até 8 peças normais em Terra.",
	["power.crystal"] = "Escolhe um elemento e elimina todas as peças desse elemento.",
	["obstacle.rock"] = "Rocha", ["obstacle.frost"] = "Gelo", ["obstacle.vine"] = "Raízes", ["obstacle.corruption"] = "Corrupção",

	-- ----------------------------------------------------------------- worlds
	["world1"] = "O Despertar",
	["world2"] = "Terras Vulcânicas",
	["world3"] = "Reino das Tempestades",
	["world.label"] = "Mundo {n}",
	["story.world1.1"] = "O primeiro grande cristal voltou a brilhar!",
	["story.world1.2"] = "A floresta encantada respira outra vez. Mas lá longe, os vulcões rugem...",
	["story.world2.1"] = "A antiga máquina elemental voltou a funcionar!",
	["story.world2.2"] = "O segundo cristal alquímico está salvo. As nuvens do Reino das Tempestades chamam por nós!",
	["story.world3.1"] = "O equilíbrio elemental foi restaurado!",
	["story.world3.2"] = "Graças a ti, aprendiz, Luméria volta a brilhar. Fogo, Água, Terra e Ar dançam de novo em harmonia.",
	["story.campaign_end"] = "Campanha concluída! Podes repetir qualquer nível para conquistar mais estrelas.",

	-- ------------------------------------------------------------------ Lumi
	["lumi.intro.1"] = "Olá, aprendiz! Eu sou a Lumi, Rainha da Alquimia. O nosso reino precisa da tua ajuda!",
	["lumi.intro.2"] = "O Grande Caos espalhou cristais instáveis por Luméria. Só a alquimia pode devolver o equilíbrio aos quatro elementos.",
	["lumi.intro.3"] = "Vamos começar pela floresta encantada. Eu estarei sempre por perto!",
	["lumi.victory.1"] = "Alquimia brilhante! Mais um pedaço do reino está salvo!",
	["lumi.victory.2"] = "Que talento! Os cristais já brilham com mais força.",
	["lumi.victory.3"] = "Perfeito! Estás a tornar-te um verdadeiro alquimista.",
	["lumi.victory.4"] = "Uau! Até as minhas asas estão a faiscar de alegria!",
	["lumi.defeat.1"] = "Quase conseguimos! Experimenta outra estratégia, aprendiz.",
	["lumi.defeat.2"] = "Não desistas! Às vezes uma fusão bem pensada muda tudo.",
	["lumi.defeat.3"] = "O caos foi teimoso desta vez. Vamos tentar de novo?",
	["lumi.discovery.1"] = "Incrível! Descobriste uma nova reação! Vou guardá-la no nosso Livro de Alquimia.",
	["lumi.discovery.2"] = "Uma nova reação! O Livro de Alquimia está a ficar cheio de segredos.",
	["lumi.discovery.3"] = "Olha só para isto! Nem eu sabia que essa mistura funcionava assim!",
	["lumi.new_mechanic"] = "Atenção! Há uma nova magia neste nível. Vou mostrar-te como funciona.",
	["lumi.level_start.1"] = "Pronto para mais uma experiência?",
	["lumi.level_start.2"] = "Concentra-te nos objetivos lá em cima!",
	["lumi.level_start.3"] = "Lembra-te: os elementos carregados são a chave das fusões.",
	["lumi.level_start.4"] = "Vamos a isto, aprendiz!",
	["lumi.combo"] = "Isso é que é uma cascata!",
	["lumi.low_moves"] = "Restam poucas jogadas! Pensa bem em cada movimento.",
	["lumi.idle"] = "Precisas de uma ajudinha? Olha para o elemento que está a brilhar.",

	-- -------------------------------------------------------------- tutorials
	["tut.first_match.1"] = "Olá, aprendiz! Eu sou a Lumi, Rainha da Alquimia. O nosso reino precisa da tua ajuda!",
	["tut.first_match.2"] = "Junta três elementos iguais para concentrares a sua energia! Arrasta o Fogo para baixo.",
	["tut.first_match.3"] = "Muito bem! Combina Fogos até recolheres 12. Repara: um dos Fogos ficou carregado de energia!",
	["tut.charge.1"] = "Quando fazes uma combinação, um dos elementos guarda a energia dos outros.",
	["tut.charge.2"] = "Faz esta combinação de quatro Águas e observa com atenção!",
	["tut.charge.3"] = "Fantástico! Criaste um elemento carregado. Agora podemos fazer verdadeira alquimia!",
	["tut.fusion.1"] = "Hoje vou ensinar-te a primeira fusão!",
	["tut.fusion.2"] = "Experimenta juntar o Fogo carregado com a Água. Vais adorar o resultado!",
	["tut.fusion.3"] = "Criaste Vapor! As fusões gastam uma jogada, mas valem muito a pena.",
	["tut.activate.1"] = "Os compostos guardam poderes enormes. Este Vapor está pronto a ser usado!",
	["tut.activate.2"] = "Toca no Vapor para o selecionares.",
	["tut.activate.3"] = "Toca novamente para libertar o seu poder!",
	["tut.activate.4"] = "Uma coluna inteira! Cria e ativa mais um Vapor para completares o nível.",
	["tut.rocks.1"] = "Rochas! Bloqueiam o caminho e só se partem com poderes elementais.",
	["tut.rocks.2"] = "Fogo carregado com Terra cria Lava. Experimenta!",
	["tut.rocks.3"] = "A Lava rebenta tudo à sua volta. Seleciona-a...",
	["tut.rocks.4"] = "...e toca novamente para a fazeres explodir junto das rochas!",
	["tut.rocks.5"] = "A Lava causa dano duplo às rochas. Excelente trabalho!",
	["tut.air.1"] = "Atenção! Há uma nova magia neste nível: o elemento Ar!",
	["tut.air.2"] = "O Ar é a espiral violeta. Faz uma combinação com ele!",
	["tut.air.3"] = "Fogo carregado com Ar cria Plasma, um raio que limpa uma linha inteira.",
	["tut.two_stage.1"] = "Alguns compostos podem ser fundidos outra vez. Vamos tentar uma reação em duas etapas!",
	["tut.two_stage.2"] = "Primeiro, junta o Fogo carregado com a Água para criares Vapor.",
	["tut.two_stage.3"] = "Não uses já esse Vapor! Experimenta combiná-lo com Ar para criares uma Tempestade!",
	["tut.two_stage.4"] = "Arrasta o Vapor para o Ar!",
	["tut.two_stage.5"] = "Uma Tempestade! Limpa a linha e a coluna onde estiver. Que poder!",
	["tut.frost.1"] = "Estes elementos estão congelados e não se podem mover.",
	["tut.frost.2"] = "Faz combinações ao lado do gelo ou usa poderes para o derreter. O Gelo composto é especialista nisso!",
	["tut.vines.1"] = "Raízes mágicas prenderam alguns elementos!",
	["tut.vines.2"] = "Combina elementos ao lado das raízes, ou usa poderes, para as cortares.",
	["tut.obsidian.1"] = "Lava e Água juntas criam Obsidiana, a pedra mais poderosa de Luméria.",
	["tut.obsidian.2"] = "Arrasta a Lava para a Água!",
	["tut.obsidian.3"] = "Agora seleciona a Obsidiana...",
	["tut.obsidian.4"] = "...e toca outra vez para partir todas as rochas do tabuleiro!",
	["tut.obsidian.5"] = "Todas as rochas de uma vez! A Obsidiana é imparável.",
	["tut.crystal.1"] = "Gelo e Fogo criam o raro Cristal. Vamos experimentar!",
	["tut.crystal.2"] = "Arrasta o Gelo para o Fogo.",
	["tut.crystal.3"] = "Seleciona o Cristal...",
	["tut.crystal.4"] = "...toca novamente e escolhe um elemento: todas essas peças desaparecem!",
	["tut.crystal.5"] = "O Poder do Cristal! Usa-o quando um elemento estiver a atrapalhar.",
	["tut.hard_rocks.1"] = "Rochas resistentes! Têm fendas e precisam de dois golpes.",
	["tut.hard_rocks.2"] = "A Lava causa dano duplo e a Obsidiana destrói qualquer rocha.",
	["tut.conveyor.1"] = "Tapetes rolantes! Esta linha desloca-se sozinha.",
	["tut.conveyor.2"] = "A cada três jogadas, os elementos do tapete avançam uma casa. Aproveita para criar combinações!",
	["tut.portals.1"] = "Portais mágicos! Os elementos que entram num portal saem pelo outro lado.",
	["tut.portals.2"] = "É assim que as peças chegam às zonas debaixo das rochas.",
	["tut.corruption.1"] = "Oh não... corrupção elemental! Esta energia escura prende os elementos.",
	["tut.corruption.2"] = "Faz combinações ao lado ou usa poderes para a purificar.",
	["tut.corruption.3"] = "Cuidado: a cada três jogadas, a corrupção pode espalhar-se!",
	["tut.finale.1"] = "Chegámos ao coração do caos. Este é o último cristal!",
	["tut.finale.2"] = "Os portais levam elementos para baixo das rochas...",
	["tut.finale.3"] = "...a corrupção vai tentar espalhar-se e o gelo protege o centro.",
	["tut.finale.4"] = "Usa tudo o que aprendeste: Tempestades, Lava e Obsidiana. Confio em ti!",

	-- ------------------------------------------------------------------- tips
	["tip.rock"] = "As rochas só se partem com poderes. Lava, Plasma, Vapor e Tempestade são ótimos para isso!",
	["tip.frost"] = "Faz combinações mesmo ao lado do gelo para o derreteres.",
	["tip.vine"] = "Combinações ao lado das raízes cortam-nas. A Poeira afeta todas de uma vez!",
	["tip.corruption"] = "Purifica a corrupção com combinações vizinhas antes que se espalhe!",
	["tip.create"] = "Primeiro cria elementos carregados, depois arrasta-os para um elemento diferente.",
	["tip.activate"] = "Toca num composto e depois toca outra vez para usares o seu poder.",
	["tip.collect"] = "Procura combinações com o elemento que precisas de recolher.",
	["tip.charge"] = "Cada combinação feita por ti cria um elemento carregado.",
}

local function interpolate(s, vars)
	if not vars then return s end
	return (s:gsub("{(%w+)}", function(k)
		local v = vars[k]
		if v == nil then return "{" .. k .. "}" end
		return tostring(v)
	end))
end

function M.get(key, vars)
	local s = M.strings[key]
	if not s then return key end
	return interpolate(s, vars)
end

function M.has(key)
	return M.strings[key] ~= nil
end

--- Element display name
function M.element(id)
	return M.get("el." .. tostring(id))
end

--- Human readable objective, e.g. "Cria 2 Vapor"
function M.goal(goal, count)
	local n = count or goal.count
	if goal.type == "clear" then
		return M.get("goal.clear." .. goal.id, { n = n })
	end
	return M.get("goal." .. goal.type, { n = n, name = goal.id and M.element(goal.id) or "" })
end

setmetatable(M, { __call = function(_, key, vars) return M.get(key, vars) end })

return M
