// lib/data/local/mock_scenario_adapter.dart
//
// Phase 2 — Harnessing: 기존 MockDioAdapter 위에 시나리오 주입 레이어를 둔다.
//
// 사용 예 (테스트/위젯테스트):
//   final scenario = MockScenarioAdapter();
//   client.raw.httpClientAdapter = scenario;
//   scenario.queue(MockScenario.unauthorized(path: '/auth/session'));
//   scenario.setGlobalLatency(const Duration(seconds: 1));
//
// 매치되지 않은 요청은 내부의 [MockDioAdapter] 로 위임되어 기존 fixture 응답이
// 그대로 반환된다 (additive — 기존 30+ 엔드포인트 보존).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'mock_dio_adapter.dart';

// ---------------------------------------------------------------------------
// Scenario value type
// ---------------------------------------------------------------------------

enum MockScenarioOutcome { success, delay, failure, unauthorized, timeout }

class MockScenario {
  /// HTTP 메서드 (대문자, 예: "POST"). null 이면 모든 메서드 매칭.
  final String? method;

  /// path 매칭 패턴 (정규식). 예: r'/auth/login', r'/tables/\d+'.
  final RegExp pathPattern;

  final MockScenarioOutcome outcome;
  final int statusCode;
  final dynamic body;
  final Duration delay;
  final Map<String, List<String>> headers;

  /// 1회만 적용할지 (true) / 영구 적용할지 (false).
  final bool oneShot;

  const MockScenario._({
    required this.method,
    required this.pathPattern,
    required this.outcome,
    required this.statusCode,
    required this.body,
    required this.delay,
    required this.headers,
    required this.oneShot,
  });

  // ---- 팩토리 -----------------------------------------------------------

  factory MockScenario.success({
    required String path,
    String? method,
    required dynamic data,
    Duration delay = Duration.zero,
    bool oneShot = true,
  }) {
    return MockScenario._(
      method: method?.toUpperCase(),
      pathPattern: RegExp(path),
      outcome: MockScenarioOutcome.success,
      statusCode: 200,
      body: {'data': data, 'error': null},
      delay: delay,
      headers: const {'content-type': ['application/json']},
      oneShot: oneShot,
    );
  }

  factory MockScenario.delay({
    required String path,
    String? method,
    required Duration latency,
    dynamic data,
    bool oneShot = true,
  }) {
    return MockScenario._(
      method: method?.toUpperCase(),
      pathPattern: RegExp(path),
      outcome: MockScenarioOutcome.delay,
      statusCode: 200,
      body: {'data': data, 'error': null},
      delay: latency,
      headers: const {'content-type': ['application/json']},
      oneShot: oneShot,
    );
  }

  factory MockScenario.failure({
    required String path,
    String? method,
    int statusCode = 500,
    String code = 'INTERNAL_ERROR',
    String message = 'Mock failure injected',
    Duration delay = Duration.zero,
    bool oneShot = true,
  }) {
    return MockScenario._(
      method: method?.toUpperCase(),
      pathPattern: RegExp(path),
      outcome: MockScenarioOutcome.failure,
      statusCode: statusCode,
      body: {
        'data': null,
        'error': {'code': code, 'message': message},
      },
      delay: delay,
      headers: const {'content-type': ['application/json']},
      oneShot: oneShot,
    );
  }

  factory MockScenario.unauthorized({
    required String path,
    String? method,
    bool oneShot = true,
  }) {
    return MockScenario.failure(
      path: path,
      method: method,
      statusCode: 401,
      code: 'UNAUTHORIZED',
      message: 'Token expired',
      oneShot: oneShot,
    );
  }

  factory MockScenario.timeout({
    required String path,
    String? method,
    bool oneShot = true,
  }) {
    return MockScenario._(
      method: method?.toUpperCase(),
      pathPattern: RegExp(path),
      outcome: MockScenarioOutcome.timeout,
      statusCode: 0,
      body: null,
      delay: const Duration(seconds: 30),
      headers: const {},
      oneShot: oneShot,
    );
  }

  bool matches(String method, String path) {
    if (this.method != null && this.method != method.toUpperCase()) return false;
    return pathPattern.hasMatch(path);
  }
}

// ---------------------------------------------------------------------------
// Scenario adapter
// ---------------------------------------------------------------------------

class MockScenarioAdapter implements HttpClientAdapter {
  MockScenarioAdapter({MockDioAdapter? fallback, this.globalLatency})
      : _fallback = fallback ?? MockDioAdapter();

  final MockDioAdapter _fallback;

  /// 모든 요청에 추가로 적용할 지연 (테스트에서 slow-network 시뮬레이션).
  Duration? globalLatency;

  final List<MockScenario> _queue = [];

  /// 매칭 로그 (테스트 assert 용).
  final List<String> hitLog = [];

  void queue(MockScenario s) => _queue.add(s);
  void queueAll(Iterable<MockScenario> ss) => _queue.addAll(ss);
  void clear() {
    _queue.clear();
    hitLog.clear();
  }

  void setGlobalLatency(Duration? d) => globalLatency = d;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method.toUpperCase();
    final path = _normalisePath(options.path);

    final idx = _queue.indexWhere((s) => s.matches(method, path));
    if (idx >= 0) {
      final s = _queue[idx];
      if (s.oneShot) _queue.removeAt(idx);
      hitLog.add('$method $path => ${s.outcome.name}');

      if (s.outcome == MockScenarioOutcome.timeout) {
        // Throw a Dio timeout — caller가 DioException 으로 받음.
        await Future<void>.delayed(s.delay);
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: options,
        );
      }

      if (s.delay > Duration.zero) await Future<void>.delayed(s.delay);
      return ResponseBody.fromString(
        jsonEncode(s.body),
        s.statusCode,
        headers: s.headers,
      );
    }

    if (globalLatency != null) {
      await Future<void>.delayed(globalLatency!);
    }
    return _fallback.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _fallback.close(force: force);

  /// `/api/v1` prefix 제거 등 fallback 어댑터와 동일한 정규화 로직.
  String _normalisePath(String raw) {
    final uri = Uri.parse(raw);
    var p = uri.path;
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    final i = p.indexOf('/api/v1');
    if (i >= 0) p = p.substring(i + '/api/v1'.length);
    return p.isEmpty ? '/' : p;
  }
}
