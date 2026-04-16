// BO REST API client with Idempotency-Key + Auth interceptors.
//
// Ported from _archive-quasar/src/boot/axios.ts (CCR-019 idempotency,
// 401 auto-refresh) and aligned with team4 BoApiClient pattern.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebs_common/ebs_common.dart';

import '../../foundation/configs/app_config.dart';
import '../local/mock_dio_adapter.dart';

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
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  final Dio _dio;

  Dio get raw => _dio;

  // -- Token management (shared with _AuthInterceptor) ---------------------

  String? _accessToken;
  Future<String?> Function()? _onTokenRefresh;

  String? get accessToken => _accessToken;

  void setToken(String? token) {
    _accessToken = token;
  }

  /// Register a callback invoked on 401 to obtain a fresh token.
  void setTokenRefreshCallback(Future<String?> Function() cb) {
    _onTokenRefresh = cb;
  }

  // -- Typed helpers -------------------------------------------------------

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
    return _parse<T>(response.data, fromJson);
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.post<dynamic>(path,
          data: data, queryParameters: queryParameters),
    );
    return _parse<T>(response.data, fromJson);
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.put<dynamic>(path, data: data),
    );
    return _parse<T>(response.data, fromJson);
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.patch<dynamic>(path, data: data),
    );
    return _parse<T>(response.data, fromJson);
  }

  Future<T> delete<T>(
    String path, {
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.delete<dynamic>(path),
    );
    return _parse<T>(response.data, fromJson);
  }

  /// Multipart upload (for skin files, etc.).
  Future<T> upload<T>(
    String path, {
    required FormData formData,
    void Function(int count, int total)? onSendProgress,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await _request(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
    return _parse<T>(response.data, fromJson);
  }

  // -- Internal ------------------------------------------------------------

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
    // Backend envelope: { data: T, error, meta } — unwrap if present.
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
// Idempotency-Key interceptor (CCR-019)
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
// Auth interceptor (Bearer token + 401 refresh retry)
// ---------------------------------------------------------------------------

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final BoApiClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _client._accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        _client._onTokenRefresh != null &&
        err.requestOptions.extra['_retry'] != true) {
      try {
        final newToken = await _client._onTokenRefresh!();
        if (newToken != null) {
          _client._accessToken = newToken;
          final opts = err.requestOptions;
          opts.extra['_retry'] = true;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _client._dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        // Fall through to original error.
      }
    }
    handler.next(err);
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
