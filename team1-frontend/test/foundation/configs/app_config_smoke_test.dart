// Smoke test for AppConfig.fromEnvironment fallback chain.
//
// dart-define 은 build-time const 이므로 runtime 에서 다양한 조합을 직접 테스트
// 할 수 없다. 대신 Non-web (io) 빌드의 host_resolver fallback 동작 + 명시
// API_BASE_URL/WS_BASE_URL override 의 기본 동작을 확인한다.
//
// EBS_SAME_ORIGIN=true + web 빌드의 browser origin 사용은 통합 테스트
// (test-results/v01-lobby/, S9 e2e) 에서 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:ebs/foundation/configs/app_config.dart';
import 'package:ebs/foundation/configs/host_resolver_io.dart' as io_resolver;

void main() {
  group('AppConfig.fromEnvironment fallback chain', () {
    test('default build (no dart-define) → localhost:8000 host+port mode', () {
      final config = AppConfig.fromEnvironment();
      // Non-web build (flutter test = vm) → resolveRuntimeHost returns ''
      // → effectiveHost = 'localhost', port default '8000'.
      expect(config.apiBaseUrl, equals('http://localhost:8000/api/v1'));
      expect(config.wsBaseUrl, equals('ws://localhost:8000'));
      expect(config.useMock, isFalse);
      expect(config.handAutoSetup, isFalse);
    });

    test('authBaseUrl mirrors apiBaseUrl (post-2026-05-06 /api/v1 정합)', () {
      final config = AppConfig.fromEnvironment();
      expect(config.authBaseUrl, equals(config.apiBaseUrl));
    });
  });

  group('host_resolver_io (non-web platforms)', () {
    test('resolveRuntimeHost returns empty string on io', () {
      expect(io_resolver.resolveRuntimeHost(), isEmpty);
    });

    test('resolveRuntimeOrigin returns empty string on io', () {
      // 새 same-origin mode fallback 동작 검증 — non-web 에서 빈 문자열 반환
      // 함으로써 AppConfig 가 host+port mode 로 자동 fallback 한다.
      expect(io_resolver.resolveRuntimeOrigin(), isEmpty);
    });
  });
}
