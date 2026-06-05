const CACHE = 'v2';
const SHELL = [
  '/index.html',
  '/ogretmen-dosyasi.html',
  '/ders-takip.html',
  '/icon-chemclass-192.png',
  '/icon-chemclass-512.png',
  '/icon-ogretmen-192.png',
  '/icon-ogretmen-512.png',
  '/icon-derstakip-192.png',
  '/icon-derstakip-512.png',
  '/manifest-chemclass.json',
  '/manifest-ogretmen.json',
  '/manifest-derstakip.json',
  '/tahta.html',
  '/sw.js',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // Supabase API calls — always network, never cache
  if (url.hostname.includes('supabase.co')) return;

  // Same-origin assets — cache-first
  if (url.origin === location.origin) {
    e.respondWith(
      caches.match(e.request).then(cached => {
        if (cached) return cached;
        return fetch(e.request).then(res => {
          if (res.ok) caches.open(CACHE).then(c => c.put(e.request, res.clone()));
          return res;
        }).catch(() => cached);
      })
    );
    return;
  }

  // CDN libraries (jsdelivr, unpkg) — cache-first, update in background
  if (url.hostname.includes('jsdelivr.net') || url.hostname.includes('unpkg.com')) {
    e.respondWith(
      caches.match(e.request).then(cached => {
        const fresh = fetch(e.request).then(res => {
          if (res.ok) caches.open(CACHE).then(c => c.put(e.request, res.clone()));
          return res;
        }).catch(() => cached);
        return cached || fresh;
      })
    );
  }
});
