const CACHE = 'v1';
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
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // For same-origin HTML/asset requests: cache-first, fallback to network
  if (url.origin === location.origin) {
    e.respondWith(
      caches.match(e.request).then(cached => cached || fetch(e.request).then(res => {
        if (res.ok) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      }))
    );
  }
  // External CDN requests: network-first, no cache
});
