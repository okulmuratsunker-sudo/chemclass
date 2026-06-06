const CACHE = 'donusturucu_v1';
const SHELL = ['/donusturucu/', '/donusturucu/index.html', '/donusturucu/manifest-donusturucu.json'];
const CDN_HOSTS = ['cdn.jsdelivr.net', 'fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)));
  self.skipWaiting();
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return;
  if (CDN_HOSTS.some(h => url.host.includes(h))) { e.respondWith(stale(e.request)); return; }
  if (url.origin === self.location.origin) { e.respondWith(cacheFirst(e.request)); return; }
});
async function cacheFirst(req) {
  const cached = await caches.match(req);
  if (cached) return cached;
  try {
    const res = await fetch(req);
    if (res.ok) (await caches.open(CACHE)).put(req, res.clone());
    return res;
  } catch {
    if (req.mode === 'navigate') return caches.match('/donusturucu/index.html');
    return new Response('Offline', { status: 503 });
  }
}
async function stale(req) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(req);
  const fresh = fetch(req).then(r => { if (r.ok) cache.put(req, r.clone()); return r; }).catch(() => cached);
  return cached || fresh;
}
