import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class CompetitionRepository {
  CompetitionRepository(this._client);
  final BoApiClient _client;

  Future<List<Competition>> listCompetitions({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Competition>>(
      '/competitions',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Competition> getCompetition(int id) async {
    return _client.get<Competition>(
      '/competitions/$id',
      fromJson: (json) => Competition.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Competition> createCompetition(Map<String, dynamic> data) async {
    return _client.post<Competition>(
      '/competitions',
      data: data,
      fromJson: (json) => Competition.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Competition> updateCompetition(
    int id,
    Map<String, dynamic> data,
  ) async {
    return _client.put<Competition>(
      '/competitions/$id',
      data: data,
      fromJson: (json) => Competition.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteCompetition(int id) async {
    await _client.delete<dynamic>('/competitions/$id');
  }
}

final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return CompetitionRepository(ref.watch(boApiClientProvider));
});
