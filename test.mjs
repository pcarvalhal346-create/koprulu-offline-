import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createGame,advance,startQueue,sendFleet,prices,production,fastForward,validateSave,storageCapacity} from './engine.mjs';
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
