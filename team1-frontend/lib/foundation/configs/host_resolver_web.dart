// Host resolver (Flutter Web) — `window.location.hostname` 으로 브라우저
// origin host 자동 추출. LAN IP / localhost 둘 다 같은 코드로 작동.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String resolveRuntimeHost() {
  try {
    final h = html.window.location.hostname ?? '';
    return h;
  } catch (_) {
    return '';
  }
}
