// Blind Structure providers — list + levels for the Settings Blind Structure tab.
//
// Backend_HTTP.md §BlindStructure: series-nested CRUD.
// Provider는 family(seriesId)로 받아 series 스코프 유지.
// UI에 series selector가 도입될 때까지 호출부에서 임시 seriesId=1 사용 (B-F005).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/settings_repository.dart';

/// Blind structures for a given series (nested path per docs).
final blindStructureListProvider =
    FutureProvider.family<List<BlindStructure>, int>((ref, seriesId) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.listBlindStructures(seriesId);
});

/// Levels for a single blind structure, keyed by structure ID.
/// (문서 누락 경로 — B-F004 보강 대기)
final blindStructureLevelsProvider =
    FutureProvider.family<List<BlindStructureLevel>, int>(
  (ref, blindStructureId) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listBlindStructureLevels(blindStructureId);
  },
);
