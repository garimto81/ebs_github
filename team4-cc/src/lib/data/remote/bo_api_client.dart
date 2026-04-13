// BO REST API client with Idempotency-Key interceptor (CCR-019).
//
// Every mutation request (POST/PATCH/PUT/DELETE) automatically receives an
// `Idempotency-Key` header. API-05 edit history 2026-04-10 records CCR-003
// making this field required across API-01/API-05/API-06.

import 'package:dio/dio.dart';

import '../../foundation/utils/uuid_idempotency.dart';

class BoApiClient {
  BoApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(_IdempotencyInterceptor());
  }

  final Dio _dio;

  Dio get raw => _dio;
}

class _IdempotencyInterceptor extends Interceptor {
  static const _mutationMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutationMethods.contains(options.method.toUpperCase())) {
      // Only generate if caller did not provide one explicitly.
      options.headers.putIfAbsent(
        UuidIdempotency.headerName,
        UuidIdempotency.generate,
      );
    }
    handler.next(options);
  }
}
