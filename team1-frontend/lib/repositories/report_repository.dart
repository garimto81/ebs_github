import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';

/// Available report types matching backend GET /reports/{report_type}.
enum ReportType {
  handsSummary('hands-summary'),
  playerStats('player-stats'),
  sessionLog('session-log'),
  tableActivity('table-activity');

  const ReportType(this.value);
  final String value;
}

class ReportRepository {
  ReportRepository(this._client);
  final BoApiClient _client;

  /// Fetch a report by type (backend: GET /Reports/{reportType}).
  /// Returns the raw report data; shape varies by report type.
  Future<Map<String, dynamic>> getReport(
    ReportType reportType, {
    Map<String, dynamic>? params,
  }) async {
    return _client.get<Map<String, dynamic>>(
      '/Reports/${reportType.value}',
      queryParameters: params,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(boApiClientProvider));
});
