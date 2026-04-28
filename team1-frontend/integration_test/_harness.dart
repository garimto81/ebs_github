// integration_test/_harness.dart
//
// Phase 4 — 모든 E2E 시나리오 공통 부트스트랩.
// - MockScenarioAdapter 를 boApiClient 에 주입
// - 결정론적 환경: useMock=true 강제, 외부 네트워크 0
// - Provider override 헬퍼 노출

import 'package:ebs_lobby/app.dart';
import 'package:ebs_lobby/data/local/mock_dio_adapter.dart';
import 'package:ebs_lobby/data/local/mock_scenario_adapter.dart';
import 'package:ebs_lobby/data/remote/bo_api_client.dart';
import 'package:ebs_lobby/foundation/configs/app_config.dart';
import 'package:ebs_lobby/foundation/observability/logger.dart';
import 'package:ebs_lobby/foundation/observability/logger_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 테스트 컨텍스트 — 시나리오 주입과 hit 검증에 사용.
class E2EHarness {
  E2EHarness({MockDioAdapter? fallback})
      : scenario = MockScenarioAdapter(fallback: fallback ?? MockDioAdapter()),
        logger = ConsoleLogger(minLevel: LogLevel.debug);

  final MockScenarioAdapter scenario;
  final ConsoleLogger logger;

  /// 테스트용 ProviderContainer override 목록.
  List<Override> overrides() {
    return [
      // useMock=true 로 강제 + scenario 어댑터 주입
      appConfigProvider.overrideWithValue(
        const AppConfig(
          apiBaseUrl: 'http://test.local/api/v1',
          wsBaseUrl: 'ws://test.local',
          useMock: true,
        ),
      ),
      // boApiClient 를 우리가 직접 만들어 scenario adapter 부착
      boApiClientProvider.overrideWith((ref) {
        final client = BoApiClient(baseUrl: 'http://test.local/api/v1');
        client.raw.httpClientAdapter = scenario;
        return client;
      }),
      // 모든 인터셉터 로깅이 ConsoleLogger 로 캡처되도록
      appLoggerProvider.overrideWithValue(logger),
    ];
  }

  /// MaterialApp 을 ProviderScope 로 감싸 반환.
  Widget buildTestApp() {
    return ProviderScope(
      overrides: overrides(),
      child: const EbsLobbyApp(),
    );
  }

  /// 테스트 정리.
  void reset() {
    scenario.clear();
  }

  /// scenario 의 hit log 가 특정 패턴을 포함하는지.
  bool hitContains(String pattern) {
    return scenario.hitLog.any((h) => h.contains(pattern));
  }
}

/// Dio 의 mock 어댑터에서 사용한 테스트 자격 증명.
class TestCredentials {
  static const email = 'admin@ebs.test';
  static const password = 'mock-password';
}
