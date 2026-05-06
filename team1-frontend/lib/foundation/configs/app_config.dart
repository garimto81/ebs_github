import 'host_resolver.dart' as host_resolver;

class AppConfig {
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool useMock;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.useMock,
  });

  /// 2026-05-06: backend auth router prefix `/api/v1` 정합 후
  /// authDio 도 `/api/v1` baseURL 사용 (이전: root). frontend `/auth/login`
  /// 호출 → 최종 `/api/v1/auth/login` 정상 라우팅.
  String get authBaseUrl => apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    // Primary: EBS_BO_HOST + EBS_BO_PORT (unified naming, build-time const)
    const host = String.fromEnvironment('EBS_BO_HOST', defaultValue: '');
    const port = String.fromEnvironment('EBS_BO_PORT', defaultValue: '8000');

    // 2026-05-06 동적 host fallback — Flutter Web 에서 build-time host 미설정
    // 시 window.location.hostname 사용. LAN IP 다른 PC 에서도 자동 작동.
    // mobile/desktop build 에서는 host_resolver 가 빈 문자열 반환 → localhost.
    final runtimeHost = host.isNotEmpty ? host : host_resolver.resolveRuntimeHost();
    final effectiveHost = runtimeHost.isNotEmpty ? runtimeHost : 'localhost';

    final apiBase = const bool.hasEnvironment('API_BASE_URL')
        ? const String.fromEnvironment('API_BASE_URL')
        : 'http://$effectiveHost:$port/api/v1';

    final wsBase = const bool.hasEnvironment('WS_BASE_URL')
        ? const String.fromEnvironment('WS_BASE_URL')
        : 'ws://$effectiveHost:$port';

    return AppConfig(
      apiBaseUrl: apiBase,
      wsBaseUrl: wsBase,
      useMock: const bool.fromEnvironment('USE_MOCK', defaultValue: false),
    );
  }
}
