/// Web localStorage 구현.
library;

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'cc_settings_storage.dart' show CcLastSession;

CcLastSession? loadLastSession(String key) {
  try {
    final raw = html.window.localStorage[key];
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return CcLastSession.fromJson(json);
  } catch (_) {
    return null;
  }
}

Future<void> saveLastSession(String key, CcLastSession s) async {
  html.window.localStorage[key] = jsonEncode(s.toJson());
}

Future<void> clearLastSession(String key) async {
  html.window.localStorage.remove(key);
}
