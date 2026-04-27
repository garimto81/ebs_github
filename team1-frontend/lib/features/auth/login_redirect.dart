// lib/features/auth/login_redirect.dart
//
// Phase 3 — /login?redirect=<encoded-path> 파라미터 안전 파싱 + 복귀 라우팅.
//
// 보안 규칙
// - 외부 URL 차단: scheme/host 가 포함된 경우 거부 (open redirect 방어)
// - allowed prefix 화이트리스트만 허용 (router 가 알고 있는 경로)
// - 복귀 실패 시 default fallback ('/lobby')

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class LoginRedirect {
  LoginRedirect._();

  static const _defaultDestination = '/lobby';

  /// router 가 인지하는 경로 prefix 화이트리스트.
  /// 새 라우트 추가 시 본 목록도 갱신해야 redirect 가 통과한다.
  static const _allowedPrefixes = <String>[
    '/lobby',
    '/tables/',
    '/players',
    '/staff',
    '/settings',
    '/graphic-editor',
    '/reports',
  ];

  /// /login?redirect=... 의 raw 값을 받아 안전한 경로로 정규화.
  /// 부적절하면 [_defaultDestination] 반환.
  static String resolveDestination(String? raw) {
    if (raw == null || raw.isEmpty) return _defaultDestination;

    String decoded;
    try {
      decoded = Uri.decodeComponent(raw);
    } catch (_) {
      return _defaultDestination;
    }

    // 외부 URL 차단
    if (decoded.contains('://')) return _defaultDestination;
    if (decoded.startsWith('//')) return _defaultDestination;
    if (!decoded.startsWith('/')) return _defaultDestination;

    // 화이트리스트 prefix 검증
    final isAllowed = _allowedPrefixes.any(
      (p) => decoded == p || decoded.startsWith('$p/') || decoded.startsWith('$p?'),
    );
    if (!isAllowed) return _defaultDestination;

    return decoded;
  }

  /// 로그인 성공 직후 호출.
  /// LoginScreen 내부에서:
  ///   final raw = GoRouterState.of(context).uri.queryParameters['redirect'];
  ///   LoginRedirect.go(context, raw);
  static void go(BuildContext context, String? rawRedirectParam) {
    final dest = resolveDestination(rawRedirectParam);
    GoRouter.of(context).go(dest);
  }
}
