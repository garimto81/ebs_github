import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class SeriesRepository {
  SeriesRepository(this._client);
  final BoApiClient _client;

  Future<List<Series>> listSeries({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Series>>(
      '/Series',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Series.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Series> getSeries(int id) async {
    return _client.get<Series>(
      '/Series/$id',
      fromJson: (json) => Series.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Series> createSeries(Map<String, dynamic> data) async {
    return _client.post<Series>(
      '/Series',
      data: data,
      fromJson: (json) => Series.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Series> updateSeries(int id, Map<String, dynamic> data) async {
    return _client.put<Series>(
      '/Series/$id',
      data: data,
      fromJson: (json) => Series.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteSeries(int id) async {
    await _client.delete<dynamic>('/Series/$id');
  }

  // -- Competitions under a series ----------------------------------------

  Future<List<Competition>> listCompetitions({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Competition>>(
      '/Competitions',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Competition> createCompetition(Map<String, dynamic> data) async {
    return _client.post<Competition>(
      '/Competitions',
      data: data,
      fromJson: (json) => Competition.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Competition> updateCompetition(
      int id, Map<String, dynamic> data) async {
    return _client.put<Competition>(
      '/Competitions/$id',
      data: data,
      fromJson: (json) => Competition.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteCompetition(int id) async {
    await _client.delete<dynamic>('/Competitions/$id');
  }

  // -- WSOP LIVE sync -----------------------------------------------------

  Future<Map<String, dynamic>> triggerSync() async {
    return _client.post<Map<String, dynamic>>(
      '/Sync/Trigger',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    return _client.get<Map<String, dynamic>>(
      '/Sync/Status',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return SeriesRepository(ref.watch(boApiClientProvider));
});
