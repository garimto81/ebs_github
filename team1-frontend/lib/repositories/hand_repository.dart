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
      '/Hands',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Hand.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Hand> getHand(int id) async {
    return _client.get<Hand>(
      '/Hands/$id',
      fromJson: (json) => Hand.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<HandAction>> getActions(int handId) async {
    return _client.get<List<HandAction>>(
      '/Hands/$handId/Actions',
      fromJson: (json) => (json as List)
          .map((e) => HandAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<HandPlayer>> getPlayers(int handId) async {
    return _client.get<List<HandPlayer>>(
      '/Hands/$handId/Players',
      fromJson: (json) => (json as List)
          .map((e) => HandPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final handRepositoryProvider = Provider<HandRepository>((ref) {
  return HandRepository(ref.watch(boApiClientProvider));
});
