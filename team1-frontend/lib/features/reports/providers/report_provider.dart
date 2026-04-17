// Report providers — fetch report data by type using ReportRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/report_repository.dart';

/// Fetches report data for a given [ReportType].
/// Returns the raw map whose shape varies per report type.
final reportDataProvider =
    FutureProvider.family<Map<String, dynamic>, ReportType>(
  (ref, reportType) async {
    final repo = ref.read(reportRepositoryProvider);
    return repo.getReport(reportType);
  },
);
