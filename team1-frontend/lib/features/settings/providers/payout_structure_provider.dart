// Payout Structure providers — list for the Settings Prize Structure tab.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/payout_structure_repository.dart';

/// All payout structures.
final payoutStructureListProvider =
    FutureProvider<List<PayoutStructure>>((ref) async {
  final repo = ref.read(payoutStructureRepositoryProvider);
  return repo.listPayoutStructures();
});
