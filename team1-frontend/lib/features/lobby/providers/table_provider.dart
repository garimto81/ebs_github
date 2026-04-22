// Table list provider — ported from lobbyStore.ts tables section.
//
// Family provider keyed by flightId. Includes seat-level mutation
// methods for player_moved / player_seated / hand_started / hand_ended
// real-time WS events.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/table_repository.dart';

class TableListNotifier extends StateNotifier<AsyncValue<List<EbsTable>>> {
  TableListNotifier({required this.flightId, required TableRepository repo})
      : _repo = repo,
        super(const AsyncValue.loading());

  final int flightId;
  final TableRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listTables(
        params: {'flightId': flightId},
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(EbsTable updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final t in list)
          if (t.tableId == updated.tableId) updated else t,
      ]);
    });
  }

  void applyRemoteAdd(EbsTable added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int tableId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((t) => t.tableId != tableId).toList(),
      );
    });
  }

  /// Update table status from a `table_status_changed` WS event.
  void updateStatus(int tableId, String newStatus) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final t in list)
          if (t.tableId == tableId) t.copyWith(status: newStatus) else t,
      ]);
    });
  }

  /// Increment/decrement seated_count from player_moved / player_seated events.
  void updateSeatedCount(int tableId, {required bool increment}) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final t in list)
          if (t.tableId == tableId)
            t.copyWith(
              seatedCount: increment
                  ? (t.seatedCount ?? 0) + 1
                  : ((t.seatedCount ?? 0) - 1).clamp(0, t.maxPlayers),
            )
          else
            t,
      ]);
    });
  }

  /// Update current_game from hand_started / hand_ended events.
  void updateCurrentGame(int tableId, int? handNumber) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final t in list)
          if (t.tableId == tableId)
            t.copyWith(currentGame: handNumber)
          else
            t,
      ]);
    });
  }
}

final tableListProvider = StateNotifierProvider.family<TableListNotifier,
    AsyncValue<List<EbsTable>>, int>(
  (ref, flightId) => TableListNotifier(
    flightId: flightId,
    repo: ref.read(tableRepositoryProvider),
  ),
);
