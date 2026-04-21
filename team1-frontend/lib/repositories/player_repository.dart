import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class PlayerRepository {
  PlayerRepository(this._client);
  final BoApiClient _client;

  Future<List<Player>> listPlayers({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Player>>(
      '/Players',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Player> getPlayer(int id) async {
    return _client.get<Player>(
      '/Players/$id',
      fromJson: (json) => Player.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<Player>> searchPlayers(
    String query, {
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<Player>>(
      '/Players/Search',
      queryParameters: {'q': query, ...?params},
      fromJson: (json) => (json as List)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref.watch(boApiClientProvider));
});
