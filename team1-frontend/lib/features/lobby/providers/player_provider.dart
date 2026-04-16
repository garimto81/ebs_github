// Player list provider — ported from lobbyStore.ts players section.
//
// Global player list (not family) with search capability.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/player_repository.dart';

class PlayerListNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  PlayerListNotifier(this._repo) : super(const AsyncValue.loading());

  final PlayerRepository _repo;

  /// Fetch all players, optionally filtered by [query].
  Future<void> fetch({String? query}) async {
    state = const AsyncValue.loading();
    try {
      final list = query != null && query.isNotEmpty
          ? await _repo.searchPlayers(query)
          : await _repo.listPlayers();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(Player updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final p in list)
          if (p.playerId == updated.playerId) updated else p,
      ]);
    });
  }

  void applyRemoteAdd(Player added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int playerId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((p) => p.playerId != playerId).toList(),
      );
    });
  }

  /// Update a player's table assignment from player_moved / player_seated events.
  void updateSeat(int playerId, {int? tableId, int? seatIndex}) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final p in list)
          if (p.playerId == playerId)
            p.copyWith(
              // tableName not updated here — would need a lookup
              seatIndex: seatIndex,
            )
          else
            p,
      ]);
    });
  }
}

final playerListProvider =
    StateNotifierProvider<PlayerListNotifier, AsyncValue<List<Player>>>(
  (ref) => PlayerListNotifier(ref.read(playerRepositoryProvider)),
);

/// Current search query for the player search bar.
final playerSearchQueryProvider = StateProvider<String>((ref) => '');
