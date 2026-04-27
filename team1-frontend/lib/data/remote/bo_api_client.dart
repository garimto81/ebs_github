// BO REST API client — Phase 2 갱신.
//
// 변경점:
// - _AuthInterceptor (in-file) 제거 → 외부 AuthInterceptor (auth_interceptor.dart)
// - setTokenRefreshCallback / setAuthFailureHandler 가 onRefresh/onFailure 양쪽 wiring
// - 인터셉터 부착 시점을 bind() 메서드로 지연 → 토큰 callback wiring 후 추가
// - _IdempotencyInterceptor 는 그대로 유지

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebs_common/ebs_common.dart';

import '../../foundation/configs/app_config.dart';
import '../../foundation/observability/logger.dart';
import '../local/mock_dio_adapter.dart';
import 'auth_interceptor.dart';

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class BoApiClient {
  BoApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(_IdempotencyInterceptor());
  }

  final Dio _dio;
  AuthInterceptor? _authInterceptor;

  Dio get raw => _dio;

  // -- Token state --------------------------------------------------------

  String? _accessToken;
  String? get accessToken => _accessToken;
  void setToken(String? token) => _accessToken = token;

  // -- Auth wiring (bootstrap에서 1회 호출) -------------------------------

  /// AuthNotifier.refreshAccessToken 을 wiring 한다.
  /// onAuthFailure 는 보통 AuthNotifier.logout() 트리거.
  void bindAuth({
    required Future<String?> Function() onRefresh,
    required void Function() onAuthFailure,
    AppLogger? logger,
  }) {
    if (_authInterceptor != null) {
      _dio.interceptors.remove(_authInterceptor);
    }
    _authInterceptor = AuthInterceptor(
      dio: _dio,
      getAccessToken: () => _accessToken,
      setAccessToken: (t) => _accessToken = t,
      refreshToken: onRefresh,
      onAuthFailure: onAuthFailure,
      logger: logger,
    );
    _dio.interceptors.add(_authInterceptor!);
  }

  // -- Typed helpers ------------------------------------------------------

  Future<T> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      T Function(dynamic json)? fromJson}) async {
    final r = await _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
    return _parse<T>(r.data, fromJson);
  }

  Future<T> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      T Function(dynamic json)? fromJson}) async {
    final r = await _request(
      () => _dio.post<dynamic>(path,
          data: data, queryParameters: queryParameters),
    );
    return _parse<T>(r.data, fromJson);
  }

  Future<T> put<T>(String path,
      {dynamic data, T Function(dynamic json)? fromJson}) async {
    final r = await _request(() => _dio.put<dynamic>(path, data: data));
    return _parse<T>(r.data, fromJson);
  }

  Future<T> patch<T>(String path,
      {dynamic data, T Function(dynamic json)? fromJson}) async {
    final r = await _request(() => _dio.patch<dynamic>(path, data: data));
    return _parse<T>(r.data, fromJson);
  }

  Future<T> delete<T>(String path, {T Function(dynamic json)? fromJson}) async {
    final r = await _request(() => _dio.delete<dynamic>(path));
    return _parse<T>(r.data, fromJson);
  }

  Future<T> upload<T>(
    String path, {
    required FormData formData,
    void Function(int count, int total)? onSendProgress,
    T Function(dynamic json)? fromJson,
  }) async {
    final r = await _request(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
    return _parse<T>(r.data, fromJson);
  }

  // -- Internal -----------------------------------------------------------

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toDomainError(e);
    }
  }

  T _parse<T>(dynamic body, T Function(dynamic json)? fromJson) {
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      final inner = body['data'];
      if (fromJson != null) return fromJson(inner);
      return inner as T;
    }
    if (fromJson != null) return fromJson(body);
    return body as T;
  }

  static ApiError _toDomainError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return ApiError(
          code: (error['code'] as String?) ?? 'UNKNOWN',
          message: (error['message'] as String?) ?? e.message ?? 'Unknown',
          details: error['details'],
        );
      }
    }
    return ApiError(
      code: e.response?.statusCode?.toString() ?? 'NETWORK_ERROR',
      message: e.message ?? 'Network error',
    );
  }
}

// ---------------------------------------------------------------------------
// Idempotency-Key interceptor
// ---------------------------------------------------------------------------

class _IdempotencyInterceptor extends Interceptor {
  static const _mutationMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutationMethods.contains(options.method.toUpperCase())) {
      options.headers.putIfAbsent(
        UuidIdempotency.headerName,
        UuidIdempotency.generate,
      );
    }
    handler.next(options);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final boApiClientProvider = Provider<BoApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final client = BoApiClient(baseUrl: config.apiBaseUrl);
  if (config.useMock) {
    client.raw.httpClientAdapter = MockDioAdapter();
  }
  return client;
});
