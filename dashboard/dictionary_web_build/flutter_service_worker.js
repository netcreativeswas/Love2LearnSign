'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "c42bba0477a34ec2b82a406a58de0c1b",
"version.json": "bbd416a3e7c352a85fc10f8cdc3334b7",
"splash/img/light-2x.png": "d6d032b59b4b5d23bb411201a243144e",
"splash/img/dark-4x.png": "172a6ebc29c05d4b3ccaf8d7dd2f6688",
"splash/img/light-3x.png": "831c871632c037b4fac3972be4a4f11e",
"splash/img/dark-3x.png": "831c871632c037b4fac3972be4a4f11e",
"splash/img/light-4x.png": "172a6ebc29c05d4b3ccaf8d7dd2f6688",
"splash/img/dark-2x.png": "d6d032b59b4b5d23bb411201a243144e",
"splash/img/dark-1x.png": "fd3bc830698c49020e2731d8f470b920",
"splash/img/light-1x.png": "fd3bc830698c49020e2731d8f470b920",
"index.html": "42f25e38680b1405722049dc8e5e7d19",
"/": "42f25e38680b1405722049dc8e5e7d19",
"main.dart.js": "3cf67eaee7cb86ca73b7eb9985845e48",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "6b6b0ba75614a697e1c0b507f46cc4f4",
"assets/AssetManifest.json": "433de0b23fade2867a781b12a034d226",
"assets/NOTICES": "e59144f33bc6e3c1484a13c3071a86f2",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "7e7dd1864d3008fde31affacc1f2578c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "afcb3ca58d1f37da4dc6cebf3d43a406",
"assets/fonts/MaterialIcons-Regular.otf": "a821bd6acc2ed28ebb138a27ecd80271",
"assets/assets/donation_banner_clear_966x499.png": "bd40f6906c8ddb9538d0216c7983ea1a",
"assets/assets/BnSL%2520headline-dark.png": "b95204440396196084f9f58fb4c9721e",
"assets/assets/1749223022410-smiley%2520Level%25202.json": "b21ba42190b936c604c5ddae127a2efc",
"assets/assets/1749221648708-smiley%2520Level%25201.json": "4376ec97f646ec2521e9eccc6a3fb912",
"assets/assets/BnSL%2520headline-light.png": "7ff184a7a2f58101146f4dc8a5706c60",
"assets/assets/1749221436432-smiley%2520Level%25203.json": "99773b8f31a3ea77a5d24e312ac6cc5f",
"assets/assets/icons/BnSL%2520Logo-1.png": "92e80cb72d9cdc1e22b76267150ae79b",
"assets/assets/icons/BnSL%2520Logo-2.png": "6f5bc6469b3b5d1b34a2b8b80653dc7f",
"assets/assets/icons/instagram.png": "abd4b6975cab49a241cf812181b63ec4",
"assets/assets/icons/BnSL%2520Logo-3.png": "a862b65efef78cabb61826f200f5a68a",
"assets/assets/icons/2.0x/instagram.png": "6f529448064666efd873ed16dcba5980",
"assets/assets/icons/2.0x/messenger.png": "c235249b4a46406bc89f11d82dd37556",
"assets/assets/icons/2.0x/imo.png": "7c31069ac25d3b88ad2c853c94626b0f",
"assets/assets/icons/2.0x/whatsapp.png": "a08eef8afaa9dd7dab1719a65d48273a",
"assets/assets/icons/3.0x/instagram.png": "bc120e4651b6ab58c4bbbaff69cae43a",
"assets/assets/icons/3.0x/messenger.png": "07d5e49d885fb7cdb904a2ce38bb8af8",
"assets/assets/icons/3.0x/imo.png": "63aee2974524300e76b664ed6a67a5cf",
"assets/assets/icons/3.0x/whatsapp.png": "7ea1e2a9562cef660c75eef71c919bc6",
"assets/assets/icons/messenger.png": "a45e78ae8bf9d5e2591d51510990b5b9",
"assets/assets/icons/imo.png": "a3b98f398603dd5e0413fad3526a1254",
"assets/assets/icons/Bnsl%2520Dictionary-full%2520splash%2520screen.png": "cca0a55c7a239d7e6ebca4799011340b",
"assets/assets/icons/BnSL%2520Logo.png": "46565978d33ec442ccc4ec12b64b6cca",
"assets/assets/icons/whatsapp.png": "b1ed34a653ccbd769900ca7d742cc1c1",
"assets/assets/1748970298316-smiley%2520Level%25205.json": "82c970708810631a58a912de6a9f0816",
"assets/assets/1749222529915-smiley%2520Level%25204.json": "7635b5bfdfd9b90a398240a6047aed1b",
"assets/assets/Animation%2520-%25201748970298316.json": "82c970708810631a58a912de6a9f0816",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
