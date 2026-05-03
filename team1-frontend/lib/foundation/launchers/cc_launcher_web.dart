/// Web-only implementation — same-window navigation to CC URL.
///
/// 2026-05-03 — `_blank` (new tab) → `location.assign` (same tab) 변경.
/// 사용자 의도: "하나의 창 안에서 처리". CC 가 query params (table_id, token,
/// cc_instance_id) 자동 파싱 → manual login 폼 ("Connect" 화면) 미표시.
/// 브라우저 back 버튼으로 lobby 회귀 가능.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void launchTarget(String target, {required bool isWeb}) {
  // Same-tab navigation — replaces lobby with CC. Browser history 보존.
  html.window.location.assign(target);
}
