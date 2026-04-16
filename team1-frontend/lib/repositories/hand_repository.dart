import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class HandRepository {
  HandRepository(this._client);
  final BoApiClient _client;

  Future<List<Hand>> listHands({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Hand>>(
      '/hands',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Hand.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Hand> getHand(int id) async {
    return _client.get<Hand>(
      '/hands/$id',
      fromJson: (json) => Hand.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<HandAction>> getActions(int handId) async {
    return _client.get<List<HandAction>>(
      '/hands/$handId/actions',
      fromJson: (json) => (json as List)
          .map((e) => HandAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<HandPlayer>> getPlayers(int handId) async {
    return _client.get<List<HandPlayer>>(
      '/hands/$handId/players',
      fromJson: (json) => (json as List)
          .map((e) => HandPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final handRepositoryProvider = Provider<HandRepository>((ref) {
  return HandRepository(ref.watch(boApiClientProvider));
});
