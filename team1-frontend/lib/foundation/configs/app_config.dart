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
    // ── 1. Explicit override (highest priority — debugging only) ─────────
    // API_BASE_URL + WS_BASE_URL 둘 다 명시 시 그대로 사용. 다른 모드 무시.
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

    // ── 2. Same-origin mode (DEFAULT 2026-05-12 cycle 11 — login 안정화) ─
    //
    // 이전 결함 (사용자 비판): default fallback 이 `http://<host>:<port>/api/v1`
    // 형태의 절대 URL → LAN 디바이스가 호스트 PC 의 hosts 파일에 의존하는 불안정.
    //
    // 신규 default = same-origin true.
    // Web 빌드 → browser origin (예: http://192.168.1.100:3000) 그대로 사용
    //          → /api/v1, /ws/ 호출은 nginx proxy 가 bo:8000 forward.
    //          → 어떤 port (3000/80/443/...) 든 재빌드 없이 작동.
    //          → LAN IP 다른 디바이스도 hosts 파일 없이 자동 작동.
    // Native 빌드 (windows/linux/mac) → origin 빈 문자열 → host+port fallback.
    //
    // Edge case: web 빌드인데 window.location 접근 실패 (e.g. SSR pre-render) →
    //          빈 문자열 origin → 상대 경로 `/api/v1` 로 graceful fallback.
    //          브라우저는 상대 path 를 자기 origin 으로 자동 resolve.
    const sameOrigin =
        bool.fromEnvironment('EBS_SAME_ORIGIN', defaultValue: true);
    if (sameOrigin) {
      final origin = host_resolver.resolveRuntimeOrigin();
      if (origin.isNotEmpty) {
        // Web build with origin (typical case).
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
      // Web build 인데 origin 비어있는 rare case → 상대 경로 fallback.
      // host_resolver_io.dart 는 항상 '' 반환 → 이 분기는 native build 에서는
      // 도달 안 함. host_resolver_web.dart 가 hostname 비어있는 경우만 도달.
      // 안전한 default: relative `/api/v1` (Dio 가 browser origin 으로 resolve).
      const isWebHint = bool.fromEnvironment('dart.library.html');
      if (isWebHint) {
        return AppConfig(
          apiBaseUrl: '/api/v1',
          wsBaseUrl: '/ws',
          useMock:
              const bool.fromEnvironment('USE_MOCK', defaultValue: false),
          handAutoSetup: const bool.fromEnvironment('HAND_AUTO_SETUP',
              defaultValue: false),
        );
      }
      // Native build → origin empty → fall through to host+port mode.
    }

    // ── 3. Host + Port mode (native build / non-proxy dev) ───────────────
    // Primary: EBS_BO_HOST + EBS_BO_PORT. Default localhost.
    // Web 빌드는 same-origin 으로 이미 처리됨 — 이 분기는 native build 전용.
    const host = String.fromEnvironment('EBS_BO_HOST', defaultValue: '');
    const port = String.fromEnvironment('EBS_BO_PORT', defaultValue: '8000');

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
