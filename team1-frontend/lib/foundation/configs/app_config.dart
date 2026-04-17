class AppConfig {
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool useMock;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.useMock,
  });

  String get authBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  factory AppConfig.fromEnvironment() {
    // Primary: EBS_BO_HOST + EBS_BO_PORT (unified naming)
    const host = String.fromEnvironment('EBS_BO_HOST', defaultValue: '');
    const port = String.fromEnvironment('EBS_BO_PORT', defaultValue: '8000');

    // Fallback: direct URL override
    final apiBase = host.isNotEmpty
        ? 'http://$host:$port/api/v1'
        : const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:8000/api/v1',
          );

    final wsBase = host.isNotEmpty
        ? 'ws://$host:$port'
        : const String.fromEnvironment(
            'WS_BASE_URL',
            defaultValue: 'ws://localhost:8000',
          );

    return AppConfig(
      apiBaseUrl: apiBase,
      wsBaseUrl: wsBase,
      useMock: const bool.fromEnvironment('USE_MOCK', defaultValue: false),
    );
  }
}
