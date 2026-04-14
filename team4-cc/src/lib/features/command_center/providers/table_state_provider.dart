// Table FSM provider (BS-05-00 §Table FSM vs HandFSM boundary, CCR-031).
//
// TableFSM governs whether the CC can operate at all:
//   EMPTY / CLOSED  -> CC disabled, read-only
//   SETUP           -> seat editing allowed, hand start blocked
//   LIVE            -> HandFSM active, full CC operation
//   PAUSED          -> HandFSM frozen, all actions disabled
//   RESERVED_TABLE  -> reserved for future use

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/table_fsm.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TableStateNotifier extends StateNotifier<TableFsm> {
  TableStateNotifier() : super(TableFsm.empty);

  /// Transition to a new table state.
  void transition(TableFsm next) => state = next;

  /// Open table for setup.
  void openTable() {
    assert(
      state == TableFsm.empty || state == TableFsm.reservedTable,
      'openTable requires empty or reservedTable, got $state',
    );
    state = TableFsm.setup;
  }

  /// Go live (setup -> live).
  void goLive() {
    assert(state == TableFsm.setup, 'goLive requires setup, got $state');
    state = TableFsm.live;
  }

  /// Pause operations (live -> paused).
  void pause() {
    assert(state == TableFsm.live, 'pause requires live, got $state');
    state = TableFsm.paused;
  }

  /// Resume operations (paused -> live).
  void resume() {
    assert(state == TableFsm.paused, 'resume requires paused, got $state');
    state = TableFsm.live;
  }

  /// Close table (any -> closed).
  void closeTable() {
    state = TableFsm.closed;
  }

  /// Reset to empty (closed -> empty, for reassignment).
  void reset() {
    state = TableFsm.empty;
  }

  /// Force state (server sync / reconnect).
  void forceState(TableFsm next) => state = next;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final tableStateProvider =
    StateNotifierProvider<TableStateNotifier, TableFsm>(
  (ref) => TableStateNotifier(),
);

/// Derived: whether CC operations are allowed (table is live).
final isTableLiveProvider = Provider<bool>((ref) {
  return ref.watch(tableStateProvider) == TableFsm.live;
});

/// Derived: whether seat editing is allowed (setup or live).
final canEditSeatsProvider = Provider<bool>((ref) {
  final fsm = ref.watch(tableStateProvider);
  return fsm == TableFsm.setup || fsm == TableFsm.live;
});
