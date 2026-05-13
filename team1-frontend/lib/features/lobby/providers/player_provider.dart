// Player list provider — Cycle 21 W3 (Players_HandHistory_API.md v1.0.0).
//
// 이전 (Reports cascade 시대): /players 가 bare List<Player> 반환했다고 가정.
// 현재 (Reports 폐기 + cursor 페이징): /players → {items, nextCursor, hasMore}.
//
// 점진 도입: fetch()/search() 는 cursor 를 모두 누적하여 List<Player> 를 반환
// (UI PlayersScreen 은 List 단일 입력 — 무한 스크롤 도입은 후속 cycle).
// WebSocket 패치(remote update/add/delete)는 그대로 유지.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/player_repository.dart';

class PlayerListNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  PlayerListNotifier(this._repo) : super(const AsyncValue.loading());

  final PlayerRepository _repo;

  /// Fetch all players, optionally filtered by [query].
  /// cursor 페이지를 자동 누적하여 단일 `List<Player>` 로 반환.
  Future<void> fetch({String? query}) async {
    state = const AsyncValue.loading();
    try {
      final list = query != null && query.isNotEmpty
          ? await _repo.searchAll(query)
          : await _repo.fetchAll();
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
