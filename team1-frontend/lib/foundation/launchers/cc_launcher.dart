/// CC launch dispatcher — conditional import for web vs desktop.
///
/// SG-008-b11 v1.2 (2026-05-03 — Web variant):
///   POST /tables/{id}/launch-cc → response.cc_url (browser) or .deep_link (desktop).
///   Lobby `_handleLaunchCc` calls this with the resolved target URL.
///
/// Web platform uses `dart:html` window.open via `cc_launcher_web.dart`.
/// Desktop platform uses stub logger (url_launcher 패키지 추가 시 교체).
library;

import 'cc_launcher_stub.dart'
    if (dart.library.html) 'cc_launcher_web.dart' as impl;

/// Open CC launch target. On web, opens new browser tab.
/// On desktop, currently logs (deep-link integration pending team4 cascade).
void launchCcTarget(String target, {required bool isWeb}) {
  impl.launchTarget(target, isWeb: isWeb);
}
