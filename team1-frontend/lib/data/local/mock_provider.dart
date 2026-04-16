// lib/data/local/mock_provider.dart — Provides a Dio instance wired with
// MockDioAdapter when AppConfig.useMock is true.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/configs/app_config.dart';
import 'mock_dio_adapter.dart';

/// Creates a [Dio] instance. When [AppConfig.useMock] is true the underlying
/// HTTP adapter is replaced with [MockDioAdapter] so every request returns
/// canned data without touching the network.
///
/// Usage in a Riverpod provider graph:
/// ```dart
/// final dioProvider = Provider<Dio>((ref) {
///   return createDio(AppConfig.fromEnvironment());
/// });
/// ```
Dio createDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  if (config.useMock) {
    dio.httpClientAdapter = MockDioAdapter();
  }

  return dio;
}

/// Riverpod provider for the application-wide [Dio] instance.
final dioProvider = Provider<Dio>((ref) {
  return createDio(AppConfig.fromEnvironment());
});
