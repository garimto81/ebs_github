// Blind Structure providers — list + levels for the Settings Blind Structure tab.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/settings_repository.dart';

/// All blind structures.
final blindStructureListProvider =
    FutureProvider<List<BlindStructure>>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.listBlindStructures();
});

/// Levels for a single blind structure, keyed by structure ID.
final blindStructureLevelsProvider =
    FutureProvider.family<List<BlindStructureLevel>, int>(
  (ref, blindStructureId) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listBlindStructureLevels(blindStructureId);
  },
);
