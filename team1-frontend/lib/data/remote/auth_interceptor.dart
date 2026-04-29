// lib/data/remote/auth_interceptor.dart
//
// G-3 교정: 401 자동 refresh + 동시성 안전 큐잉.
//
// 기존 bo_api_client.dart 의 _AuthInterceptor 를 대체한다.
// - 단일 in-flight refresh: N개 동시 401 도 refresh 호출 1회로 묶음
// - 펜딩 큐: refresh 진행 중 들어온 401 요청은 대기, 결과로 일괄 재시도/실패
// - 무한 retry 방지: extra['_authRetried'] 플래그 1회만 허용
// - refresh 실패: 모든 펜딩 요청 401 로 reject + onAuthFailure 콜백 (logout)

import 'dart:async';

import 'package:dio/dio.dart';

import '../../foundation/observability/logger.dart';

typedef TokenRefresher = Future<String?> Function();
typedef AuthFailureHandler = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.getAccessToken,
    required this.setAccessToken,
    required this.refreshToken,
    this.onAuthFailure,
    this.logger,
  });

  final Dio dio;
  final String? Function() getAccessToken;
  final void Function(String?) setAccessToken;
  final TokenRefresher refreshToken;
  final AuthFailureHandler? onAuthFailure;
  final AppLogger? logger;

  // ---- Concurrency control --------------------------------------------------

  Completer<String?>? _refreshInFlight;

  // ---- Request: Bearer 헤더 주입 --------------------------------------------

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['_skipAuth'] != true) {
      final token = getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  // ---- Error: 401 처리 ------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final opts = err.requestOptions;

    final isRefreshCall = opts.path.endsWith('/auth/refresh');
    final alreadyRetried = opts.extra['_authRetried'] == true;

    if (status != 401 || isRefreshCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    logger?.breadcrumb('http', '401 → refresh attempt', data: {
      'path': opts.path,
      'method': opts.method,
    });

    try {
      final newToken = await _coalescedRefresh();
      if (newToken == null || newToken.isEmpty) {
        logger?.warning('Auth refresh returned empty; logging out',
            context: {'path': opts.path});
        onAuthFailure?.call();
        handler.next(err);
        return;
      }

      opts.extra['_authRetried'] = true;
      opts.headers['Authorization'] = 'Bearer $newToken';
      final retryResponse = await dio.fetch(opts);
      logger?.breadcrumb('http', '401 retry success', data: {
        'path': opts.path,
        'status': retryResponse.statusCode,
      });
      handler.resolve(retryResponse);
    } catch (e, st) {
      logger?.error('Auth refresh failed', error: e, st: st, context: {
        'path': opts.path,
      });
      onAuthFailure?.call();
      handler.next(err);
    }
  }

  /// 동일 시점 refresh 호출이 여러 개 들어오면 단일 Completer 로 합친다.
  Future<String?> _coalescedRefresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshInFlight = completer;

    Future<void>(() async {
      try {
        final token = await refreshToken();
        if (token != null && token.isNotEmpty) {
          setAccessToken(token);
        }
        completer.complete(token);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _refreshInFlight = null;
      }
    });

    return completer.future;
  }
}
