/// CC 마지막 세션 설정 영속 (SG-008-b11 v1.4 — issue 2).
///
/// Web: dart:html localStorage. Desktop: in-memory stub (향후 shared_preferences 권장).
///
/// stand-alone CC 진입 시 비번 1 field 만 표시하기 위해, 마지막 성공 인증의
/// non-secret config (email, BO URL, table_id, ws_url) 만 저장.
/// **token / password 절대 저장 금지** (5분 짧은 수명 + 보안).
library;

import 'cc_settings_storage_stub.dart'
    if (dart.library.html) 'cc_settings_storage_web.dart' as impl;

/// 영속 가능한 마지막 세션 메타데이터.
class CcLastSession {
  final String? email;
  final String? boBaseUrl;
  final int? tableId;
  final String? wsUrl;

  const CcLastSession({
    this.email,
    this.boBaseUrl,
    this.tableId,
    this.wsUrl,
  });

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (boBaseUrl != null) 'boBaseUrl': boBaseUrl,
        if (tableId != null) 'tableId': tableId,
        if (wsUrl != null) 'wsUrl': wsUrl,
      };

  factory CcLastSession.fromJson(Map<String, dynamic> j) => CcLastSession(
        email: j['email'] as String?,
        boBaseUrl: j['boBaseUrl'] as String?,
        tableId: j['tableId'] is int
            ? j['tableId'] as int
            : int.tryParse('${j['tableId'] ?? ''}'),
        wsUrl: j['wsUrl'] as String?,
      );
}

class CcSettingsStorage {
  CcSettingsStorage._();

  static const _key = 'ebs_cc_last_config';

  /// localStorage 에서 last session 읽기. 없거나 corrupted → null.
  static CcLastSession? loadLastSession() => impl.loadLastSession(_key);

  /// localStorage 에 last session 저장. password/token 미포함.
  static Future<void> saveLastSession(CcLastSession s) =>
      impl.saveLastSession(_key, s);

  /// localStorage 에서 last session 삭제 (logout / reset).
  static Future<void> clearLastSession() => impl.clearLastSession(_key);
}
