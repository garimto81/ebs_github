// Payout Structure providers — list for the Settings Prize Structure tab.
//
// Backend_HTTP.md §PayoutStructure: series-nested CRUD.
// Provider family(seriesId). B-F005 이전에는 호출부에서 seriesId=1 default.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/payout_structure_repository.dart';

/// Payout structures for a given series (nested path per docs).
final payoutStructureListProvider =
    FutureProvider.family<List<PayoutStructure>, int>((ref, seriesId) async {
  final repo = ref.read(payoutStructureRepositoryProvider);
  return repo.listPayoutStructures(seriesId);
});
