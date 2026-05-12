// Host resolver (Flutter Web) — `window.location.hostname` / origin 으로 브라우저
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

/// Returns the full browser origin (`protocol://host:port`) used by
/// `EBS_SAME_ORIGIN=true` mode. nginx proxy 배포 (port 3000 / 80 / 443) 가
/// 어떤 port 든 자기 origin 으로 `/api/`, `/ws/` 호출 → port hardcoding 제거.
String resolveRuntimeOrigin() {
  try {
    final loc = html.window.location;
    final protocol = loc.protocol; // "http:" or "https:"
    final host = loc.host;         // includes port: "192.168.1.100:3000"
    if (host.isEmpty) return '';
    return '$protocol//$host';
  } catch (_) {
    return '';
  }
}
