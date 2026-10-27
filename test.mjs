import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createGame,advance,startQueue,sendFleet,previewFleet,expansionProgress,prices,production,fastForward,validateSave,storageCapacity} from './engine.mjs';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const M=60_000,H=60*M;
test('universo criado com 20 bots em posições únicas e save válido',()=>{
 const s=createGame(1_000_000);assert.equal(s.bots.length,20);assert.equal(new Set(s.bots.map(b=>`${b.galaxy}:${b.system}:${b.position}`)).size,20);assert.equal(validateSave(s),true);
});
test('produção de recursos ao longo de uma hora e capacidade máxima',()=>{
 const s=createGame(1_000_000),start=s.player.resources.metal,rate=production(s.player.buildings).metal;
 advance(s,1_000_000+H);assert.ok(s.player.resources.metal>=start+rate-.01);assert.ok(s.player.resources.metal<=storageCapacity(1));
});
test('fila de edifícios debita recursos e conclui mais tarde',()=>{
 const s=createGame(1_000_000),before=s.player.resources.metal;
 const res=startQueue(s,'building','metal');assert.equal(res.ok,true);assert.ok(s.player.resources.metal<before);
 const finish=s.player.queues.building.endAt;advance(s,finish-1);assert.equal(s.player.buildings.metal,3);
 advance(s,finish+1);assert.equal(s.player.buildings.metal,4);assert.equal(s.player.queues.building,null);
});
test('restrições impedem gastar naves inexistentes e criar novas filas em paralelo',()=>{
 const s=createGame(1_000_000);assert.equal(startQueue(s,'building','solar').ok,true);assert.equal(startQueue(s,'building','metal').ok,false);
 assert.equal(sendFleet(s,1,{lightFighter:30}).ok,false);
});
test('espionagem gera relatório, regresso da sonda e desaparecimento da missão',()=>{
 const s=createGame(1_000_000),starting=s.player.ships.probe;
 assert.equal(sendFleet(s,1,{probe:1},'spy').ok,true);assert.equal(s.player.ships.probe,starting-1);
 advance(s,1_000_000+H);assert.equal(s.player.ships.probe,starting);assert.equal(s.fleets.length,0);assert.ok(s.reports.some(x=>x.title==='Relatório de espionagem'));
});
test('ataque produz relatório e não deixa contagens negativas',()=>{
 const s=createGame(1_000_000),res=sendFleet(s,1,{lightFighter:3,smallCargo:1},'attack');assert.equal(res.ok,true);
 advance(s,1_000_000+H);assert.ok(s.reports.some(x=>x.title.includes('combate')||x.title==='Ataque repelido'));
 assert.ok(Object.values(s.player.ships).every(v=>v>=0));assert.ok(s.fleets.length===0);
});
test('bots evoluem sozinhos e avanço rápido mantém save válido',()=>{
 const s=createGame(Date.now()),n=s.bots[0].actions;
 fastForward(s,3);assert.ok(s.bots[0].actions>n);assert.equal(validateSave(JSON.parse(JSON.stringify(s))),true);
});
test('não permite pesquisas sem laboratório e capacidades acima de zero',()=>{
 const s=createGame(1_000_000);s.player.buildings.lab=0;
 assert.equal(startQueue(s,'research','weapons').ok,false);assert.ok(storageCapacity(0)>0);
});

// Conteúdo específico do protótipo Koprulu.
import {RACES,LEADERS,LEADERS_BY_RACE,migrateSave,recruitLeader,selectLeader,useLeaderAbility,leaderCost} from './engine.mjs';
test('três raças com líderes iniciais escolhidos e 20 rivais de várias raças',()=>{
 assert.deepEqual(Object.keys(RACES).sort(),['protoss','terran','zerg']);
 for(const [race,heroes] of Object.entries(LEADERS_BY_RACE)){
   assert.equal(heroes.length,3);
   const s=createGame(1_000_000,race,heroes[2]);
   assert.equal(s.player.race,race);assert.equal(s.player.activeLeader,heroes[2]);
   assert.deepEqual(s.player.ownedLeaders,[heroes[2]]);
   assert.equal(validateSave(s),true);
 }
 const bots=createGame(1_000_000).bots;
 assert.equal(new Set(bots.map(b=>b.race)).size,3);
 bots.forEach(b=>assert.equal(LEADERS[b.leaderId].race,b.race));
});
test('recrutar líder desconta recursos e permite mudar de comandante',()=>{
 const s=createGame(1_000_000,'terran','raynor');
 const cost=leaderCost(s,'swann');const before=s.player.resources.metal;
 assert.equal(recruitLeader(s,'swann').ok,true);
 assert.equal(s.player.resources.metal,before-cost.metal);
 assert.equal(selectLeader(s,'swann').ok,true);
 assert.equal(s.player.activeLeader,'swann');
 assert.equal(recruitLeader(s,'karax').ok,false);
 assert.equal(recruitLeader(s,'swann').ok,false);
});
test('poder do comandante dá recursos e entra em recarga',()=>{
 const s=createGame(1_000_000,'terran','swann');
 const before=s.player.resources.metal;
 assert.equal(useLeaderAbility(s).ok,true);
 assert.ok(s.player.resources.metal>before);
 assert.equal(useLeaderAbility(s).ok,false);
 advance(s,s.lastSimulated+30*60_000);
 assert.equal(useLeaderAbility(s).ok,true);
});

test('pré-visualizar ataque calcula combustível, duração e carga sem alterar o universo',()=>{
 const s=createGame(1_000_000),before=structuredClone(s);
 const preview=previewFleet(s,1,{lightFighter:3,smallCargo:1});
 assert.equal(preview.ok,true);
 assert.equal(preview.count,4);
 assert.equal(preview.fuel,7);
 assert.equal(preview.travelMs,59_000);
 assert.equal(preview.capacity,5150);
 assert.equal(preview.slotsUsed,0);
 assert.equal(preview.slotsMax,2);
 assert.deepEqual(s,before);
 assert.equal(sendFleet(s,1,{lightFighter:3,smallCargo:1}).ok,true);
 assert.equal(s.player.resources.deuterium,before.player.resources.deuterium-preview.fuel);
 assert.deepEqual(s.fleets[0].ships,preview.ships);
 assert.equal(s.fleets[0].travelMs,preview.travelMs);
 assert.equal(s.fleets[0].arrivesAt,before.lastSimulated+preview.travelMs);
});

test('pré-visualizar espionagem não gasta sondas e prevê o regresso',()=>{
 const s=createGame(1_000_000),before=structuredClone(s);
 const preview=previewFleet(s,1,{probe:1},'spy');
 assert.equal(preview.ok,true);
 assert.equal(preview.fuel,3);
 assert.equal(preview.capacity,0);
 assert.deepEqual(s,before);
 assert.equal(sendFleet(s,1,{probe:1},'spy').ok,true);
 advance(s,before.lastSimulated+preview.travelMs);
 assert.equal(s.fleets[0].phase,'returning');
 assert.equal(s.fleets[0].arrivesAt,before.lastSimulated+2*preview.travelMs);
 advance(s,before.lastSimulated+2*preview.travelMs);
 assert.equal(s.fleets.length,0);
 assert.equal(s.player.ships.probe,before.player.ships.probe);
});

test('pré-visualização e lançamento rejeitam a mesma seleção inválida sem gastar recursos',()=>{
 const cases=[
  [999,{lightFighter:1},'attack'],
  [1,{lightFighter:1},'transport'],
  [1,{},'attack'],
  [1,{probe:1},'attack'],
  [1,{lightFighter:-1},'attack'],
  [1,{lightFighter:1.5},'attack'],
  [1,{lightFighter:NaN},'attack'],
  [1,{lightFighter:Infinity},'attack'],
  [1,{lightFighter:100001},'attack'],
  [1,{lightFighter:5},'attack'],
  [1,{},'spy'],
  [1,{probe:1,lightFighter:1},'spy'],
 ];
 for(const args of cases){
  const s=createGame(1_000_000),before=structuredClone(s);
  const preview=previewFleet(s,...args);
  assert.equal(preview.ok,false);
  assert.deepEqual(sendFleet(s,...args),{ok:false,message:preview.message});
  assert.deepEqual(s,before);
 }
});

test('combustível insuficiente mantém a estimativa e o lançamento verifica o saldo atual',()=>{
 const s=createGame(1_000_000),ships={lightFighter:3,smallCargo:1};
 const preview=previewFleet(s,1,ships);
 s.player.resources.deuterium=preview.fuel-1;
 const before=structuredClone(s),blocked=previewFleet(s,1,ships);
 assert.equal(blocked.ok,false);
 assert.equal(blocked.fuel,preview.fuel);
 assert.equal(blocked.travelMs,preview.travelMs);
 assert.equal(sendFleet(s,1,ships).ok,false);
 assert.deepEqual(s,before);
 s.player.resources.deuterium=preview.fuel;
 assert.equal(sendFleet(s,1,ships).ok,true);
 assert.equal(s.player.resources.deuterium,0);
});

test('posições de frota ocupadas bloqueiam envios e computadores libertam uma posição',()=>{
 const s=createGame(1_000_000);
 assert.equal(sendFleet(s,1,{lightFighter:1}).ok,true);
 assert.equal(sendFleet(s,1,{lightFighter:1}).ok,true);
 const before=structuredClone(s),preview=previewFleet(s,1,{probe:1},'spy');
 assert.equal(preview.ok,false);
 assert.equal(sendFleet(s,1,{probe:1},'spy').ok,false);
 assert.deepEqual(s,before);
 s.player.tech.computer=1;
 const available=previewFleet(s,1,{probe:1},'spy');
 assert.equal(available.ok,true);
 assert.equal(available.slotsUsed,2);
 assert.equal(available.slotsMax,3);
 s.player.tech.computer=20;
 assert.equal(previewFleet(s,1,{probe:1},'spy').slotsMax,8);
});

test('objetivos só avançam quando construções e pesquisas terminam e sobrevivem à exportação',()=>{
 const s=createGame(1_000_000);
 assert.equal(expansionProgress(s).completed,0);
 for(const [index,[category,key]] of [['building','solar'],['building','metal'],['research','weapons'],['building','shipyard']].entries()){
  assert.equal(startQueue(s,category,key).ok,true);
  assert.equal(expansionProgress(s).completed,index,'uma ordem pendente não conclui o objetivo');
  const queue=category==='research'?'research':'building';
  advance(s,s.player.queues[queue].endAt);
  assert.equal(expansionProgress(s).completed,index+1);
 }
 assert.equal(expansionProgress(s).next,null);
 const restored=JSON.parse(JSON.stringify(s));
 assert.equal(validateSave(restored),true);
 assert.deepEqual(expansionProgress(restored),expansionProgress(s));
});

test('guia aceita objetivos fora de ordem e saves das três raças sem alterar o progresso',()=>{
 for(const race of Object.keys(RACES)){
  const s=createGame(1_000_000,race);
  assert.equal(startQueue(s,'research','weapons').ok,true);
  assert.equal(startQueue(s,'building','metal').ok,true);
  advance(s,Math.max(s.player.queues.research.endAt,s.player.queues.building.endAt));
  const before=structuredClone(s),progress=expansionProgress(s);
  assert.equal(progress.completed,2);
  assert.equal(progress.next.id,'solar');
  assert.equal(progress.goals.find(g=>g.id==='weapons').complete,true);
  assert.deepEqual(s,before,'consultar objetivos não consome recursos nem muda o save');
 }
});

test('instalação do cache offline encontra todos os ficheiros e ícones PWA válidos',async()=>{
 const handlers={};let cached=[],activated=false,install;
 const base=new URL('./',import.meta.url);
 const sw=await readFile(new URL('sw.js',base),'utf8');
 vm.runInNewContext(sw,{
  self:{addEventListener:(type,handler)=>handlers[type]=handler,skipWaiting:()=>{activated=true}},
  caches:{open:async()=>({addAll:async assets=>{
   cached=[...assets];
   for(const asset of assets){
    const file=await readFile(new URL(asset==='./'?'index.html':asset,base));
    assert.ok(file.length>0,asset);
   }
  }})}
 });
 handlers.install({waitUntil:promise=>install=promise});
 await install;
 assert.equal(activated,true);
 for(const asset of ['./','./app.js','./engine.mjs','./styles.css','./manifest.webmanifest'])assert.ok(cached.includes(asset),asset);
 const manifest=JSON.parse(await readFile(new URL('manifest.webmanifest',base),'utf8'));
 for(const icon of manifest.icons){
  assert.ok(cached.includes(icon.src),icon.src);
  const png=await readFile(new URL(icon.src,base));
  assert.deepEqual([...png.subarray(0,8)],[137,80,78,71,13,10,26,10]);
  assert.equal(`${png.readUInt32BE(16)}x${png.readUInt32BE(20)}`,icon.sizes);
 }
});
