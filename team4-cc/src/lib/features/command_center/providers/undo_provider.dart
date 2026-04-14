// Undo Stack Riverpod provider (BS-05-05).
//
// Exposes UndoStack as reactive state for CC undo history UI.
// State = List<UndoableEvent> (unmodifiable snapshot for widget rebuild).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/undo_stack.dart';

/// Notifier that wraps [UndoStack] and exposes reactive state.
class UndoNotifier extends StateNotifier<List<UndoableEvent>> {
  UndoNotifier() : super([]);

  final _stack = UndoStack();

  /// Whether there are events available to undo.
  bool get canUndo => _stack.canUndo;

  /// Total events in the stack.
  int get length => _stack.length;

  /// Push a reversible event. Irreversible events are silently rejected.
  void push(UndoableEvent event) {
    if (_stack.push(event)) {
      state = _stack.all;
    }
  }

  /// Undo (pop) the most recent event.
  ///
  /// Returns the popped event so the caller can reverse-apply it,
  /// or `null` if the stack was empty.
  UndoableEvent? undo() {
    final event = _stack.pop();
    if (event != null) {
      state = _stack.all;
    }
    return event;
  }

  /// Clear the stack on HandCompleted.
  void clearOnHandComplete() {
    _stack.clear();
    state = [];
  }

  /// Get a page of undo history (page 0 = most recent).
  List<UndoableEvent> getPage(int page) => _stack.getPage(page);

  /// Total number of pages.
  int get pageCount => _stack.pageCount;
}

/// Main undo stack provider.
final undoStackProvider =
    StateNotifierProvider<UndoNotifier, List<UndoableEvent>>(
  (ref) => UndoNotifier(),
);

/// Derived: whether undo is available (for button enable/disable).
final canUndoProvider = Provider<bool>((ref) {
  final events = ref.watch(undoStackProvider);
  return events.isNotEmpty;
});
