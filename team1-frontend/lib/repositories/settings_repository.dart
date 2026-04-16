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

  // -- Blind Structures ---------------------------------------------------

  Future<List<BlindStructure>> listBlindStructures({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<BlindStructure>>(
      '/blind-structures',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => BlindStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<BlindStructure> getBlindStructure(int id) async {
    return _client.get<BlindStructure>(
      '/blind-structures/$id',
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BlindStructure> createBlindStructure(
      Map<String, dynamic> data) async {
    return _client.post<BlindStructure>(
      '/blind-structures',
      data: data,
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BlindStructure> updateBlindStructure(
    int id,
    Map<String, dynamic> data,
  ) async {
    return _client.put<BlindStructure>(
      '/blind-structures/$id',
      data: data,
      fromJson: (json) =>
          BlindStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteBlindStructure(int id) async {
    await _client.delete<dynamic>('/blind-structures/$id');
  }

  // -- Blind Structure Levels ---------------------------------------------

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
