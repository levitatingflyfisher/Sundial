{{flutter_js}}
{{flutter_build_config}}
// Flutter's default bootstrap, plus a config that keeps every engine fetch on
// this origin. canvasKitBaseUrl: the copy `flutter build web` always puts in
// canvaskit/ (otherwise Google's CDN unless built with --no-web-resources-cdn).
// fontFallbackBaseUrl: where the engine fetches a fallback font when text has
// a glyph the app's bundled fonts lack (ř, box drawing, symbols, CJK, emoji).
// It is root-relative on purpose: every OpenHearth PWA is served from
// levitatingflyfisher.github.io/<App>/, and the site at that origin's root
// (the levitatingflyfisher.github.io repo) mirrors Google's fallback fonts
// once under /fonts/flutter-fallback/ for the whole fleet. Same origin, only
// fetched on demand. The engine's eager Roboto request 404s there by design.
// Guarded by conformance C13 and hearthbuild's deploy-pwa.sh.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "/fonts/flutter-fallback/"
  }
});
