import 'host_resolver.dart' as host_resolver;

class AppConfig {
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool useMock;

  /// 1 hand auto-setup hook (Cycle 2, Issue #239).
  /// When true, the Lobby will auto-execute the 1-hand demo wire on startup:
  ///   table 생성 → CC 할당 → RFID monitor → cascade:lobby-hand-ready publish.
  /// Enabled via `--dart-define=HAND_AUTO_SETUP=true`.
  /// Default: false (manual operation only).
  final bool handAutoSetup;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.useMock,
    this.handAutoSetup = false,
  });

  /// 2026-05-06: backend auth router prefix `/api/v1` 정합 후
  /// authDio 도 `/api/v1` baseURL 사용 (이전: root). frontend `/auth/login`
  /// 호출 → 최종 `/api/v1/auth/login` 정상 라우팅.
  String get authBaseUrl => apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    // ── Explicit override (highest priority) ─────────────────────────────
    // 명시적 URL 지정 시 그대로 사용. Same-origin / host+port 모드보다 우선.
    if (const bool.hasEnvironment('API_BASE_URL') ||
        const bool.hasEnvironment('WS_BASE_URL')) {
      final apiBase = const bool.hasEnvironment('API_BASE_URL')
          ? const String.fromEnvironment('API_BASE_URL')
          : '';
      final wsBase = const bool.hasEnvironment('WS_BASE_URL')
          ? const String.fromEnvironment('WS_BASE_URL')
          : '';
      if (apiBase.isNotEmpty && wsBase.isNotEmpty) {
        return AppConfig(
          apiBaseUrl: apiBase,
          wsBaseUrl: wsBase,
          useMock:
              const bool.fromEnvironment('USE_MOCK', defaultValue: false),
          handAutoSetup: const bool.fromEnvironment('HAND_AUTO_SETUP',
              defaultValue: false),
        );
      }
    }

    // ── Same-origin mode (web only, Docker deployment default) ───────────
    // 2026-05-12 cycle 9 — nginx proxy 패턴 정착. Lobby Web 이 자기 origin
    // (http://<host>:3000) 으로 /api/, /ws/ 호출 → nginx 가 bo:8000 forward.
    // port hardcoding 제거: 어느 port 에 배포(3000/80/443/...) 해도 재빌드 불필요.
    // LAN IP (192.168.x.x:3000) 디바이스도 자기 origin 기준으로 자동 작동.
    // Non-web build 에서는 resolveRuntimeOrigin() 가 빈 문자열 → 아래 host+port 모드 fallback.
    const sameOrigin =
        bool.fromEnvironment('EBS_SAME_ORIGIN', defaultValue: false);
    if (sameOrigin) {
      final origin = host_resolver.resolveRuntimeOrigin();
      if (origin.isNotEmpty) {
        final wsBase = origin.startsWith('https://')
            ? origin.replaceFirst('https://', 'wss://')
            : origin.replaceFirst('http://', 'ws://');
        return AppConfig(
          apiBaseUrl: '$origin/api/v1',
          wsBaseUrl: wsBase,
          useMock:
              const bool.fromEnvironment('USE_MOCK', defaultValue: false),
          handAutoSetup: const bool.fromEnvironment('HAND_AUTO_SETUP',
              defaultValue: false),
        );
      }
    }

    // ── Host + Port mode (legacy / dev — flutter run -d windows/chrome) ──
    // Primary: EBS_BO_HOST + EBS_BO_PORT (unified naming, build-time const)
    const host = String.fromEnvironment('EBS_BO_HOST', defaultValue: '');
    const port = String.fromEnvironment('EBS_BO_PORT', defaultValue: '8000');

    // 2026-05-06 동적 host fallback — Flutter Web 에서 build-time host 미설정
    // 시 window.location.hostname 사용. LAN IP 다른 PC 에서도 자동 작동.
    // mobile/desktop build 에서는 host_resolver 가 빈 문자열 반환 → localhost.
    final runtimeHost =
        host.isNotEmpty ? host : host_resolver.resolveRuntimeHost();
    final effectiveHost = runtimeHost.isNotEmpty ? runtimeHost : 'localhost';

    return AppConfig(
      apiBaseUrl: 'http://$effectiveHost:$port/api/v1',
      wsBaseUrl: 'ws://$effectiveHost:$port',
      useMock: const bool.fromEnvironment('USE_MOCK', defaultValue: false),
      handAutoSetup:
          const bool.fromEnvironment('HAND_AUTO_SETUP', defaultValue: false),
    );
  }
}
