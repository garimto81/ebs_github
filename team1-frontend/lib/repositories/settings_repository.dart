import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class SettingsRepository {
  SettingsRepository(this._client);
  final BoApiClient _client;

  // -- Config sections ----------------------------------------------------

  Future<Map<String, dynamic>> getConfig(String section) async {
    return _client.get<Map<String, dynamic>>(
      '/configs/$section',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getAllConfigs() async {
    return _client.get<Map<String, dynamic>>(
      '/configs',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> updateConfig(
    String section,
    Map<String, dynamic> values,
  ) async {
    return _client.put<Map<String, dynamic>>(
      '/configs/$section',
      data: values,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // -- Blind Structures (series-nested per Backend_HTTP.md §BlindStructure) ----
  // 모든 blind-structure 조회/변경은 series 컨텍스트 필수.
  // Flight 적용 구조는 /flights/:id/blind-structure 별도 경로 (BO team2 소유).

  Future<List<BlindStructure>> listBlindStructures(
    int seriesId, {
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<BlindStructure>>(
      '/series/$seriesId/blind-structures',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => BlindStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<BlindStructure> getBlindStructure(int seriesId, int bsId) async {
    return _client.get<BlindStructure>(
      '/series/$seriesId/blind-structures/$bsId',
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BlindStructure> createBlindStructure(
    int seriesId,
    Map<String, dynamic> data,
  ) async {
    return _client.post<BlindStructure>(
      '/series/$seriesId/blind-structures',
      data: data,
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BlindStructure> updateBlindStructure(
    int seriesId,
    int bsId,
    Map<String, dynamic> data,
  ) async {
    return _client.put<BlindStructure>(
      '/series/$seriesId/blind-structures/$bsId',
      data: data,
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteBlindStructure(int seriesId, int bsId) async {
    await _client.delete<dynamic>(
      '/series/$seriesId/blind-structures/$bsId',
    );
  }

  // -- Blind Structure Levels (문서 명세 없음 — B-F004 보강 대기) -------------
  // 현재 경로는 team1 자의적 설계. BO 문서 확정 후 재조정 필요.
  // 호출 유지하되 BO 구현 완료까지 호출 실패 시 graceful degradation 가정.

  Future<List<BlindStructureLevel>> listBlindStructureLevels(
    int blindStructureId,
  ) async {
    return _client.get<List<BlindStructureLevel>>(
      '/blind-structures/$blindStructureId/levels',
      fromJson: (json) => (json as List)
          .map((e) =>
              BlindStructureLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<BlindStructureLevel> createBlindStructureLevel(
    int blindStructureId,
    Map<String, dynamic> data,
  ) async {
    return _client.post<BlindStructureLevel>(
      '/blind-structures/$blindStructureId/levels',
      data: data,
      fromJson: (json) =>
          BlindStructureLevel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BlindStructureLevel> updateBlindStructureLevel(
    int blindStructureId,
    int levelId,
    Map<String, dynamic> data,
  ) async {
    return _client.put<BlindStructureLevel>(
      '/blind-structures/$blindStructureId/levels/$levelId',
      data: data,
      fromJson: (json) =>
          BlindStructureLevel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteBlindStructureLevel(
    int blindStructureId,
    int levelId,
  ) async {
    await _client.delete<dynamic>(
      '/blind-structures/$blindStructureId/levels/$levelId',
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(boApiClientProvider));
});
