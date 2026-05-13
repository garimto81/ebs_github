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

  // Cycle 21 W3 — `getReport(type)` 제거. backend `/api/v1/reports/{type}` 는
  // Players_HandHistory_API.md §8 에 따라 폐기. hand history 는 hand_history
  // feature 의 HandHistoryRepository, audit logs 는 본 listAuditLogs 사용.
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(boApiClientProvider));
});
