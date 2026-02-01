// Service Worker - Minimal (offline support optional later)
self.addEventListener('install', event => {
  // Skip waiting to activate immediately
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  // Take control of all clients
  event.waitUntil(clients.claim());
});

self.addEventListener('fetch', event => {
  // Just fetch from network; later we can cache here
  event.respondWith(fetch(event.request));
});