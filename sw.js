const CACHE = 'koprulu-offline-v4';
const ASSETS = ['./','./index.html','./styles.css','./app.js','./engine.mjs','./manifest.webmanifest','./icons/icon-192.png','./icons/icon-512.png'];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(Promise.all([caches.keys().then(names=>Promise.all(names.filter(n=>n!==CACHE).map(n=>caches.delete(n)))),self.clients.claim()]));
});
self.addEventListener('fetch', event => {
  const req=event.request;
  if(req.method!=='GET')return;
  const u=new URL(req.url);
  if(u.origin!==self.location.origin)return;
  // Esta aplicação não possui endpoints autenticados. Apenas ficheiros estáticos são guardados.
  if(!(/\.(?:js|mjs|css|png|webmanifest|html)$/.test(u.pathname)||u.pathname===new URL('./',self.registration.scope).pathname))return;
  event.respondWith(caches.match(req).then(cached=>cached||fetch(req).then(resp=>{
    if(resp.ok){const cp=resp.clone();caches.open(CACHE).then(cache=>cache.put(req,cp));}
    return resp;
  })));
});
