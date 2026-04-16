import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class AuditLogRepository {
  AuditLogRepository(this._client);
  final BoApiClient _client;

  Future<List<AuditLog>> listAuditLogs({
    Map<String, dynamic>? filters,
  }) async {
    return _client.get<List<AuditLog>>(
      '/audit-logs',
      queryParameters: filters,
      fromJson: (json) => (json as List)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Map<String, dynamic>> getReport(
    String type, {
    Map<String, dynamic>? params,
  }) async {
    return _client.get<Map<String, dynamic>>(
      '/reports/$type',
      queryParameters: params,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(boApiClientProvider));
});
