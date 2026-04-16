class AppConfig {
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool useMock;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.useMock,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000/api/v1',
      ),
      wsBaseUrl: String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'ws://localhost:8000',
      ),
      useMock: bool.fromEnvironment(
        'USE_MOCK',
        defaultValue: true,
      ),
    );
  }
}
