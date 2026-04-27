// lib/foundation/bootstrap_provider.dart
//
// Phase 2 + Phase 3 — 앱 부팅 wiring 단일 진입점.
//
// - boApiClient.bindAuth(...)  : G-3 fix. 401 자동 refresh 회로 활성화.
// - lobbyWsLifecycleProvider   : G-4 fix. auth 상태 기반 connect/disconnect.
// - logger 주입               : Phase 3. AuthInterceptor → AppLogger.
//
// app.dart 의 EbsLobbyApp.build() 에서 ref.watch(bootstrapProvider) 호출.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../data/remote/ws_lifecycle.dart';
import '../features/auth/auth_provider.dart';
import 'observability/logger_provider.dart';

final bootstrapProvider = Provider<bool>((ref) {
  final logger = ref.watch(appLoggerProvider);

  // ----- G-3: AuthInterceptor wiring -----
  final api = ref.watch(boApiClientProvider);
  final authNotifier = ref.read(authProvider.notifier);

  api.bindAuth(
    onRefresh: authNotifier.refreshAccessToken,
    onAuthFailure: () {
      logger.warning('Auth failure handler invoked → forced logout');
      authNotifier.logout();
    },
    logger: logger,
  );

  // ----- G-4: WS lifecycle -----
  ref.watch(lobbyWsLifecycleProvider);

  logger.info('Bootstrap complete', context: {
    'baseUrl': ref.read(appConfigProvider).apiBaseUrl,
    'useMock': ref.read(appConfigProvider).useMock,
  });

  return true;
});
