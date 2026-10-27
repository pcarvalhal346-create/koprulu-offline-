import {createGame,advance,fastForward,startQueue,sendFleet,BUILDINGS,TECH,UNITS,DEFENSE,RESOURCE_NAMES,prices,affordable,production,storageCapacity,scorePlayer,scoreBot,timeRemaining,coords,validateSave,migrateSave,VERSION,RACES,LEADERS,LEADERS_BY_RACE,raceUnitName,raceBuildingName,leaderCost,recruitLeader,selectLeader,useLeaderAbility} from './engine.mjs';
const $=id=>document.getElementById(id);
const MINUTE = 60_000;
const fmt=n=>Math.floor(Number(n)||0).toLocaleString('pt-PT');
const date=ms=>new Date(ms).toLocaleString('pt-PT',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'});
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const navItems=[['overview','⌂','Visão geral'],['buildings','▥','Edifícios'],['research','⌬','Pesquisas'],['leaders','♛','Líderes'],['shipyard','✈','Hangar'],['galaxy','✧','Galáxia'],['fleets','⇄','Frotas'],['reports','▤','Relatórios'],['settings','⚙','Opções']];
let state,view='overview',modalBot=null,lastUiRefresh=0,savePending=false,toastTimer=0,startingRace='terran',startingLeader='raynor';
const gameNow=()=>Date.now()+(state?.offsetMs||0);
const duration=at=>timeRemaining(at,gameNow());
const canAfford=(cat,key,level=0,qty=1)=>affordable(state.player.resources,prices(cat,key,level,qty));
const enough=(cost)=>Object.keys(RESOURCE_NAMES).map(k=>`<span class="${state.player.resources[k]+.001<(cost[k]||0)?'lacking':''}">${k==='metal'?'M':k==='crystal'?'C':'D'} ${fmt(cost[k]||0)}</span>`).join(' · ');
const btn=(label,action,extra='',disabled=false)=>`<button class="btn ${extra}" data-action="${action}" ${disabled?'disabled':''}>${label}</button>`;
const status=p=>p?'<span class="pill">EM PRODUÇÃO</span>':'';
function notify(msg,error=false){const el=$('toast');el.textContent=msg;el.className=`show${error?' error':''}`;clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.className='',3600);}
function navRender(){
  $('nav').innerHTML=navItems.map(([key,icon,label])=>`<button class="nav-item ${key===view?'active':''}" data-nav="${key}" aria-current="${key===view?'page':'false'}"><span aria-hidden="true">${icon}</span>${label}</button>`).join('');
  $('page-title').textContent=navItems.find(x=>x[0]===view)?.[2]||'Koprulu';
  document.documentElement.dataset.race=state?.player?.race||startingRace;
}
function resourcesRender(){const p=state.player,prod=production(p.buildings,p.race,p.activeLeader),cap=storageCapacity(p.buildings.storage);
  const r=[['metal','⛏','Minerais',`+${fmt(prod.metal)}/h`],['crystal','◈','Cristal',`+${fmt(prod.crystal)}/h`],['deuterium','◉','Gás Vespeno',`+${fmt(prod.deuterium)}/h`]];
  $('resources').innerHTML=r.map(([k,i,label,sub])=>`<div class="resource"><div class="res-label"><b>${i}</b>${label}</div><div class="res-num" title="${fmt(p.resources[k])}">${fmt(p.resources[k])}</div><div class="res-sub">${sub} · limite ${fmt(cap)}</div></div>`).join('')+`<div class="resource energy ${prod.energyRatio<1?'low':''}"><div class="res-label"><b>⚡</b> Energia</div><div class="res-num">${fmt(prod.energyProduced-prod.energyUsed)}</div><div class="res-sub">${fmt(prod.energyProduced)} / ${fmt(prod.energyUsed)} · ${Math.floor(prod.energyRatio*100)}% eficiência</div></div>`;
  $('connection').textContent=navigator.onLine?'◉ Jogo local ativo':'◉ Sem internet — ativo';
  $('save-indicator').textContent=savePending?'● A guardar':'● Guardado no iPhone';
}
function queueBlock(queue){const q=state.player.queues[queue];if(!q)return '';
  const definition=q.category==='building'?BUILDINGS[q.key]:q.category==='research'?TECH[q.key]:q.category==='ship'?UNITS[q.key]:DEFENSE[q.key];
  return `<div class="card queue-card"><div class="queue-head"><div><div class="mini-kicker">Fila ativa</div><strong>${q.category==='ship'?raceUnitName(state.player.race,q.key):q.category==='building'?raceBuildingName(state.player.race,q.key):definition?.name||q.key} ${q.qty>1?'×'+q.qty:''}</strong></div><span class="queue-timer" data-countdown="${q.endAt}">${duration(q.endAt)}</span></div><div class="progress"><span style="width:${Math.max(3,Math.min(100,100-(q.endAt-gameNow())/Math.max(1,300000)*100))}%"></span></div></div>`;
}
function overview(){const p=state.player,prod=production(p.buildings,p.race,p.activeLeader),race=RACES[p.race],leader=LEADERS[p.activeLeader];
  const fleets=state.fleets.filter(f=>f.owner==='player');const latest=state.reports[0];
  return `<section class="hero card"><div class="hero-copy"><div class="mini-kicker">${race.symbol} ${race.name.toUpperCase()} · PLANETA PRINCIPAL · ${coords(p)}</div><h2>${escape(p.planetName)}</h2><p>Setor Koprulu · ${escape(race.tagline)}. Liderança de ${escape(leader.name)}. Expande o planeta, desenvolve a frota e conquista o setor — mesmo sem internet.</p><div class="btn-row">${btn('Desenvolver minas','goto:buildings')}${btn('Explorar galáxia','goto:galaxy','secondary')}${btn('Ver líderes','goto:leaders','ghost')}</div></div><div class="hero-planet"><div class="stars"></div></div></section>
  <div class="stats-row"><div class="card stat-card"><div class="number">${scorePlayer(state).toLocaleString('pt-PT')}</div><div class="caption">Poder do império</div></div><div class="card stat-card"><div class="number">${state.bots.length}</div><div class="caption">Impérios rivais</div></div><div class="card stat-card"><div class="number">${fleets.length}</div><div class="caption">Frotas no espaço</div></div></div>
  <section style="margin-top:23px"><div class="section-heading"><div><h2>Operações em curso</h2><p>Atualizadas automaticamente pelo relógio do jogo.</p></div></div><div class="stack">${queueBlock('building')}${queueBlock('research')}${queueBlock('hangar')}${!Object.values(p.queues).some(Boolean)?'<div class="card empty">Nenhuma construção em curso. Começa pela economia.</div>':''}</div></section>
  <section style="margin-top:23px" class="info-grid"><div class="card info-card leader-summary"><h3>${leader.symbol} Comandante ${escape(leader.name)}</h3><p>${escape(leader.title)} · ${escape(leader.desc)}</p><p>${p.ownedLeaders.length} líder(es) disponíveis. ${p.abilityReadyAt<=gameNow()?'Habilidade pronta.':'Recarga ativa.'}</p>${btn('Abrir comandantes','goto:leaders','secondary small')}</div><div class="card info-card"><h3>⚡ Balanço energético</h3><p>Produção: <b>${fmt(prod.energyProduced)}</b> · Consumo: <b>${fmt(prod.energyUsed)}</b></p><p>Eficiência das minas: <b>${Math.round(prod.energyRatio*100)}%</b></p>${prod.energyRatio<1?'<p style="color:#efad8e">Constrói uma Central Solar para evitar perda de produção.</p>':''}</div><div class="card info-card"><h3>▤ Último acontecimento</h3><p><b>${escape(latest?.title||'Sem novidades')}</b></p><p>${escape(latest?.text||'')}</p><p>${date(latest?.at||gameNow())}</p></div></section>`;
}
function builds(){return `<div class="section-heading"><div><h2>Infraestruturas planetárias</h2><p>Construção de uma estrutura de cada vez. As minas produzem mesmo quando fechas o jogo.</p></div></div>${queueBlock('building')}<div class="list-grid" style="margin-top:12px">${Object.entries(BUILDINGS).map(([key,v])=>{
  const level=state.player.buildings[key]||0,cost=prices('building',key,level);const blocked=!!state.player.queues.building||!canAfford('building',key,level);
  return `<article class="card item"><div class="item-header"><div class="item-icon">${v.icon}</div><div><h3>${raceBuildingName(state.player.race,key)}</h3><p class="desc">${v.desc}</p></div></div><div class="badge-row"><span class="pill info">Nível ${level}</span>${state.player.queues.building?.key===key?status(true):''}</div><div class="item-footer"><div class="cost"><div class="muted">Próximo nível</div>${enough(cost)}</div>${btn('Construir','build:'+key,'small',blocked)}</div></article>`;
}).join('')}</div>`;}
function research(){return `<div class="section-heading"><div><h2>Árvore de tecnologias</h2><p>Investigações melhoram o desempenho militar e a capacidade de exploração.</p></div></div>${queueBlock('research')}<div class="list-grid" style="margin-top:12px">${Object.entries(TECH).map(([key,v])=>{
  const level=state.player.tech[key]||0,cost=prices('tech',key,level),blocked=!!state.player.queues.research||!canAfford('tech',key,level);
  return `<article class="card item"><div class="item-header"><div class="item-icon">${v.icon}</div><div><h3>${v.name}</h3><p class="desc">${v.desc}</p></div></div><div class="badge-row"><span class="pill info">Nível ${level}</span></div><div class="item-footer"><div class="cost">${enough(cost)}</div>${btn('Pesquisar','research:'+key,'small',blocked)}</div></article>`;
}).join('')}</div>`;}
function shipyard(){return `<div class="section-heading"><div><h2>Arsenal ${RACES[state.player.race].name}</h2><p>Unidades da tua raça. O motor mantém missões clássicas de espionagem, ataque e transporte.</p></div></div>${queueBlock('hangar')}<div class="list-grid" style="margin-top:12px">${Object.entries({...UNITS,...DEFENSE}).map(([key,v])=>{
  const cat=UNITS[key]?'ship':'defense',owned=state.player[cat==='ship'?'ships':'defense'][key]||0,need=v.needs?.shipyard||1,locked=(state.player.buildings.shipyard||0)<need,cost=prices(cat,key,0),blocked=!!state.player.queues.hangar||locked||!canAfford(cat,key);
  return `<article class="card item"><div class="item-header"><div class="item-icon">${v.icon}</div><div><h3>${cat==='ship'?raceUnitName(state.player.race,key):v.name}</h3><p class="desc">${v.desc}</p></div></div><div class="badge-row"><span class="pill info">${owned} unidades</span>${locked?`<span class="pill warn">Hangar n.º ${need} necessário</span>`:''}</div><div class="cost">Custo por unidade: ${enough(cost)}</div><div class="item-footer"><div class="qty-box"><label class="label" for="qty-${key}">Qtd.</label><input id="qty-${key}" class="number-input" type="number" inputmode="numeric" min="1" max="100" value="1" ${locked?'disabled':''}></div>${btn('Produzir',cat+':'+key,'small',blocked)}</div></article>`;
}).join('')}</div>`;}
function galaxy(){const bots=[...state.bots].sort((a,b)=>a.system-b.system||a.position-b.position);
  return `<div class="section-heading"><div><h2>Galáxia 1 · 20 impérios</h2><p>Os bots expandem a economia, constroem frotas e alguns poderão atacar-te.</p></div><span class="pill">${bots.length} rivais</span></div><div class="card table-scroll"><table class="table"><thead><tr><th>Coordenadas</th><th>Império</th><th>Poder</th><th>Ações</th></tr></thead><tbody>${bots.map(b=>`<tr><td><span class="pill info">${coords(b)}</span></td><td><div class="bot-title">${escape(b.name)}</div><div class="bot-sub"><span class="race-dot ${b.race}">${RACES[b.race]?.symbol||''} ${RACES[b.race]?.name||''}</span> · ${escape(b.style)} · ${escape(LEADERS[b.leaderId]?.name||'')}</div></td><td>${fmt(scoreBot(b))}</td><td><div class="actions">${btn('Espiar','spy:'+b.id,'ghost small',state.player.ships.probe<1)}${btn('Atacar','attack:'+b.id,'secondary small')}</div></td></tr>`).join('')}</tbody></table></div><p class="hint">Espionagem requer pelo menos uma sonda. O ataque usa as naves selecionadas no painel de missão.</p>`;}
function fleets(){const active=state.fleets;
  return `<div class="section-heading"><div><h2>Movimentos de frota</h2><p>As missões avançam com o tempo, mesmo depois de fechares o jogo.</p></div></div><div class="card">${active.length?`<div class="table-scroll"><table class="table"><thead><tr><th>Origem</th><th>Missão</th><th>Destino</th><th>Estado</th><th>Chegada</th></tr></thead><tbody>${active.map(f=>{const b=state.bots.find(b=>b.id===f.botId);return `<tr><td>${f.owner==='player'?'Tua':escape(b?.name||'Bot')}</td><td>${f.mission==='spy'?'Espionagem':'Ataque'}</td><td>${f.owner==='player'?escape(b?.name||'Planeta'):escape(state.player.planetName)}</td><td>${f.phase==='outbound'?'<span class="pill warn">A caminho</span>':'<span class="pill info">Regresso</span>'}</td><td data-countdown="${f.arrivesAt}">${duration(f.arrivesAt)}</td></tr>`}).join('')}</tbody></table></div>`:'<div class="empty">Não tens frotas em movimento. Visita a Galáxia para iniciar uma missão.</div>'}</div>`;}
function reports(){return `<div class="section-heading"><div><h2>Registo do universo</h2><p>Construções, combates, espionagem e acontecimentos recentes.</p></div><span class="pill info">${state.reports.length} registos</span></div><div class="card">${state.reports.map(r=>`<article class="report"><div class="report-dot ${r.type||''}"></div><div><div class="report-title">${escape(r.title)}</div><div class="report-date">${date(r.at)}</div><div class="report-text">${escape(r.text)}</div></div></article>`).join('')}</div>`;}
function leaders(){
  const p=state.player,r=RACES[p.race],active=LEADERS[p.activeLeader],ready=(p.abilityReadyAt||0)<=gameNow();
  return `<div class="section-heading"><div><h2>Conselho de Comando · ${r.name}</h2><p>Começaste com um líder. Recruta mais comandantes da tua raça e alterna as especialidades.</p></div><span class="pill gold">${p.ownedLeaders.length} / 3</span></div>
  <div class="card commander-feature"><div class="commander-symbol">${active.symbol}</div><div><div class="mini-kicker">LÍDER ATIVO · ${escape(r.name)}</div><h2>${escape(active.name)}</h2><p>${escape(active.title)} · ${escape(active.desc)}</p><div class="btn-row">${btn(ready?'Usar poder: '+escape(active.abilityName):'Poder em recarga','ability','',!ready)}${!ready?`<span class="pill warn" data-countdown="${p.abilityReadyAt}">${duration(p.abilityReadyAt)}</span>`:''}</div></div></div>
  <div class="list-grid leader-grid">${LEADERS_BY_RACE[p.race].map(id=>{const l=LEADERS[id],owned=p.ownedLeaders.includes(id),active=p.activeLeader===id,cost=leaderCost(state,id);return `<article class="card leader-item"><div class="leader-head"><span class="commander-mini">${l.symbol}</span><div><h3>${escape(l.name)}</h3><div class="muted">${escape(l.title)}</div></div></div><p>${escape(l.desc)}</p><div class="badge-row"><span class="pill ${owned?'':'info'}">${active?'ATIVO':owned?'RECRUTADO':'POR RECRUTAR'}</span></div>${!owned?`<div class="cost">${enough(cost)}</div>`:''}<div class="leader-footer">${active?`<span class="hint">Em comando</span>`:owned?btn('Selecionar','select-leader:'+id,'secondary small'):btn('Recrutar','recruit:'+id,'small',!affordable(p.resources,cost))}</div></article>`}).join('')}</div>
  <div class="alert">Bónus racial: ${escape(r.desc)}. O poder especial tem uma recarga de 30 minutos do tempo de jogo. Os líderes são exclusivos da raça escolhida.</div>`;
}
function startScreen(){state=null;document.documentElement.dataset.race=startingRace;$('page-title').textContent='Escolhe a tua raça';$('resources').innerHTML='';$('nav').innerHTML='';$('save-indicator').textContent='● Novo universo';$('view').innerHTML='<div class="empty">Personaliza a tua campanha para começar.</div>';
  const r=RACES[startingRace];
  $('modal').innerHTML=`<div class="start-overlay"><div class="start-shell"><div class="mini-kicker">UM UNIVERSO OFFLINE · SETOR KOPRULU</div><h1>Escolhe a tua facção</h1><p class="start-intro">Estratégia clássica de navegador com 3 raças, comandantes recrutáveis e 20 bots. Um protótipo de fã não oficial, sem servidores.</p><div class="race-choices">${Object.entries(RACES).map(([id,x])=>`<button class="race-choice ${id} ${startingRace===id?'selected':''}" data-action="choose-race:${id}" aria-pressed="${startingRace===id}"><span class="race-glyph">${x.symbol}</span><strong>${x.name}</strong><small>${escape(x.tagline)}</small></button>`).join('')}</div><div class="start-details"><div class="start-details-title"><h2>${r.symbol} ${r.name}</h2><p>${escape(r.desc)}</p></div><div class="mini-kicker">ESCOLHE O TEU LÍDER INICIAL</div><div class="start-leaders">${LEADERS_BY_RACE[startingRace].map(id=>{const x=LEADERS[id];return `<button data-action="choose-starter:${id}" class="start-leader ${startingLeader===id?'selected':''}" aria-pressed="${startingLeader===id}"><span class="leader-emoji">${x.symbol}</span><strong>${escape(x.name)}</strong><small>${escape(x.title)}</small><small>${escape(x.desc)}</small></button>`}).join('')}</div></div><div class="start-cta">${btn('Iniciar campanha com '+r.name,'begin','',false)}<span>O jogo é guardado automaticamente no iPhone.</span></div></div></div>`;
}
function settings(){return `<div class="section-heading"><div><h2>Guardar e gerir o teu universo</h2><p>Este jogo não envia os teus dados para nenhum servidor.</p></div></div><div class="settings-grid"><div class="card settings-card"><h3>▣ Cópia de segurança</h3><p>Exporta o progresso como um ficheiro JSON para a app Ficheiros do iPhone. É importante antes de remover a PWA ou limpar dados do Safari.</p><div class="btn-row">${btn('Exportar progresso','export','small')}${btn('Importar progresso','import','secondary small')}</div></div><div class="card settings-card"><h3>⏱ Testar a evolução do universo</h3><p>Este botão simula uma hora adicional: produção, construções, frotas e decisões dos bots. Útil para testar o jogo sem esperar.</p><div class="btn-row">${btn('Simular +1 hora','forward','secondary small')}</div></div><div class="card settings-card"><h3>✦ Instalar no iPhone</h3><p>Abre o site em Safari, seleciona Partilhar → Adicionar ao ecrã principal → Abrir como aplicação. Depois da primeira instalação, funciona sem internet.</p><p>O jogo exige uma publicação inicial num endereço HTTPS, como o GitHub Pages. Não necessita de servidor de jogo.</p></div><div class="card settings-card"><h3>⚙ Novo universo</h3><p>Escolhe novamente raça e líder e inicia um novo universo com 20 bots. Exporta primeiro o progresso atual.</p>${btn('Reiniciar universo','reset','danger small')}</div></div><div class="alert" style="margin-top:16px">Protótipo de fã, não oficial e sem afiliação à Blizzard ou aos criadores de OGame. Utiliza nomes de facções e líderes de StarCraft II, mas nenhuma arte nem código desses jogos. O motor e a IA são simplificados. Não é uma conversão do XGProyect-FMJ.</div>`;}
function renderView(){
  navRender();const views={overview,buildings:builds,research,leaders,shipyard,galaxy,fleets,reports,settings};
  $('view').innerHTML=(views[view]||overview)();lastUiRefresh=Date.now();
}
function renderAll(){resourcesRender();renderView()}
function updateCountdowns(){document.querySelectorAll('[data-countdown]').forEach(el=>el.textContent=duration(Number(el.dataset.countdown)))}
function modalOpen(botId,mission){
  const b=state.bots.find(b=>b.id===botId);if(!b)return;
  modalBot={botId,mission};const spy=mission==='spy';
  $('modal').innerHTML=`<div class="modal-overlay" data-action="close-bg"><div class="modal-card" role="dialog" aria-modal="true" aria-label="Preparar missão"><div class="mini-kicker">${spy?'RECONHECIMENTO':'OPERAÇÃO MILITAR'}</div><h2>${spy?'Espiar':'Atacar'} ${escape(b.name)}</h2><p>Destino ${coords(b)} · Frota de ida e volta · Combate automático no destino.</p><hr class="divider"><div class="modal-grid">${(spy?['probe']:Object.keys(UNITS).filter(k=>k!=='probe')).map(k=>`<label for="fleet-${k}"><strong>${raceUnitName(state.player.race,k)}</strong><br><span class="muted">Disponíveis: ${fmt(state.player.ships[k]||0)}</span></label><input class="number-input" data-fleet-ship="${k}" id="fleet-${k}" type="number" min="0" max="${state.player.ships[k]||0}" inputmode="numeric" value="${spy?Math.min(1,state.player.ships.probe||0):k==='lightFighter'?Math.min(3,state.player.ships.lightFighter||0):k==='smallCargo'?Math.min(1,state.player.ships.smallCargo||0):0}">`).join('')}</div><div class="hint">O combustível é retirado no lançamento. O saque é transportado conforme a capacidade das naves sobreviventes.</div><div class="modal-footer">${btn('Cancelar','close','ghost')}${btn('Enviar frota','send','')}</div></div></div>`;
}
function modalClose(){modalBot=null;$('modal').innerHTML=''}
let db;
function openDatabase(){return new Promise((resolve,reject)=>{if(!('indexedDB'in window))return reject(new Error('Sem IndexedDB'));
  const req=indexedDB.open('galaxia-classica-offline',1);
  req.onupgradeneeded=()=>{if(!req.result.objectStoreNames.contains('games'))req.result.createObjectStore('games')};
  req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);
})}
function readIDB(){return new Promise((resolve,reject)=>{const tx=db.transaction('games','readonly'),req=tx.objectStore('games').get('save');req.onsuccess=()=>resolve(req.result||null);req.onerror=()=>reject(req.error)})}
function writeIDB(snapshot){return new Promise((resolve,reject)=>{const tx=db.transaction('games','readwrite');tx.objectStore('games').put(snapshot,'save');tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error)})}
let persistChain=Promise.resolve();
function persist(){if(!state)return;
  const snapshot=typeof structuredClone==='function'?structuredClone(state):JSON.parse(JSON.stringify(state));
  savePending=true;
  persistChain=persistChain.catch(()=>{}).then(async()=>{
    try {if(db)await writeIDB(snapshot);else localStorage.setItem('galaxia-save',JSON.stringify(snapshot));}
    catch(e){try{localStorage.setItem('galaxia-save',JSON.stringify(snapshot))}catch(_){notify('Não foi possível guardar. Exporta o progresso.',true)}}
    savePending=false;
  });
  return persistChain;
}
async function load(){try{db=await openDatabase();const saved=await readIDB();if(saved)return saved;}catch(e){db=null;}try{return JSON.parse(localStorage.getItem('galaxia-save')||'null')}catch(_){return null}}
function actQueue(category,key){advance(state,gameNow());const quantity=Number($(`qty-${key}`)?.value||1);
  const result=startQueue(state,category,key,quantity);notify(result.message,!result.ok);if(result.ok){renderAll();persist();}
}
function exportSave(){advance(state,gameNow());persist();const blob=new Blob([JSON.stringify(state,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`galaxia-classica-${new Date().toISOString().slice(0,10)}.json`;document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),10000);notify('Cópia de segurança criada. Guarda o ficheiro em Ficheiros.');}
async function importSave(file){if(!file)return;try{if(file.size>8_000_000)throw Error('Ficheiro demasiado grande.');const s=JSON.parse(await file.text());migrateSave(s);if(!validateSave(s))throw Error('Ficheiro não é um jogo válido desta versão.');if(!window.confirm('Substituir o universo atual pelo ficheiro escolhido?'))return;
    state=s;advance(state,gameNow());renderAll();await persist();notify('Universo importado com sucesso.');
  }catch(err){notify(err.message||'Não foi possível importar.',true)}finally{$('import-file').value=''}}
function onClick(event){const nav=event.target.closest('[data-nav]');if(nav){view=nav.dataset.nav;renderAll();window.scrollTo({top:0,behavior:'instant'});return;}
  const el=event.target.closest('[data-action]');if(!el)return;const action=el.dataset.action;
  if(action.startsWith('choose-race:')){startingRace=action.split(':')[1];startingLeader=LEADERS_BY_RACE[startingRace][0];startScreen();return;}
  if(action.startsWith('choose-starter:')){startingLeader=action.split(':')[1];startScreen();return;}
  if(action==='begin'){state=createGame(Date.now(),startingRace,startingLeader);$('modal').innerHTML='';view='overview';renderAll();persist();notify('Bem-vindo a Koprulu!');return;}
  if(!state)return;
  if(action.startsWith('recruit:')){advance(state,gameNow());const result=recruitLeader(state,action.split(':')[1]);notify(result.message,!result.ok);if(result.ok){renderAll();persist()}return;}
  if(action.startsWith('select-leader:')){const result=selectLeader(state,action.split(':')[1]);notify(result.message,!result.ok);if(result.ok){renderAll();persist()}return;}
  if(action==='ability'){advance(state,gameNow());const result=useLeaderAbility(state);notify(result.message,!result.ok);if(result.ok){renderAll();persist()}return;}
  if(action==='close-bg'&&event.target!==el)return;
  if(action.startsWith('goto:')){view=action.split(':')[1];renderAll();return;}
  if(action.startsWith('build:'))return actQueue('building',action.split(':')[1]);
  if(action.startsWith('research:'))return actQueue('research',action.split(':')[1]);
  if(action.startsWith('ship:'))return actQueue('ship',action.split(':')[1]);
  if(action.startsWith('defense:'))return actQueue('defense',action.split(':')[1]);
  if(action.startsWith('spy:')||action.startsWith('attack:')){const [mission,id]=action.split(':');return modalOpen(Number(id),mission)}
  if(action==='close'||action==='close-bg')return modalClose();
  if(action==='send'){
    advance(state,gameNow());const ships={};for(const input of document.querySelectorAll('[data-fleet-ship]'))ships[input.dataset.fleetShip]=Number(input.value||0);
    const result=sendFleet(state,modalBot.botId,ships,modalBot.mission);notify(result.message,!result.ok);if(result.ok){modalClose();view='fleets';renderAll();persist();}return;
  }
  if(action==='export')return exportSave();
  if(action==='import')return $('import-file').click();
  if(action==='reset'){
    if(!window.confirm('Apagar o progresso atual e começar um novo universo com 20 bots? Esta ação não pode ser anulada.'))return;
    startingRace=state.player.race;startingLeader=LEADERS_BY_RACE[startingRace][0];view='overview';startScreen();notify('Escolhe uma raça e um líder para o novo universo.');return;
  }
  if(action==='forward'){advance(state,gameNow());fastForward(state,1);renderAll();persist();notify('O universo avançou uma hora.');return;}
}
async function init(){const saved=await load();if(saved)migrateSave(saved);state=validateSave(saved)?saved:null;
  document.addEventListener('click',onClick);
  $('import-file').addEventListener('change',e=>importSave(e.target.files?.[0]));
  window.addEventListener('online',()=>{if(state)resourcesRender()});window.addEventListener('offline',()=>{if(state)resourcesRender()});
  document.addEventListener('visibilitychange',()=>{if(!state)return;if(document.visibilityState==='hidden'){advance(state,gameNow());persist();}else{advance(state,gameNow());renderAll();persist();}});
  setInterval(()=>{if(document.visibilityState==='hidden'||!state)return;
    const beforeReports=state.reports.length;advance(state,gameNow());resourcesRender();updateCountdowns();
    if(state.reports.length!==beforeReports||Date.now()-lastUiRefresh>20000){if(!modalBot)renderView();}
  },1000);
  setInterval(()=>{if(state){advance(state,gameNow());persist()}},15000);
  if(state){const before=state.lastSimulated;advance(state,gameNow());renderAll();await persist();if(gameNow()-before>MINUTE)notify(`O teu universo avançou ${Math.floor((gameNow()-before)/MINUTE)} minutos desde a última visita.`);}
  else{startScreen();}
  if('serviceWorker' in navigator){try{await navigator.serviceWorker.register('./sw.js',{scope:'./'})}catch(err){console.warn('PWA sem cache:',err)}}
}
init().catch(err=>{$('view').innerHTML=`<div class="alert">Erro ao iniciar o jogo: ${escape(err.message)}. Recarrega a página.</div>`;console.error(err)});
