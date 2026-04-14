// Riverpod provider wrapper for KeyboardShortcutHandler (BS-05-06).
//
// Bridges the keyboard handler service into the Riverpod dependency graph
// so that action callbacks flow through existing providers (action buttons,
// card input, seat navigation).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/card.dart';
import '../services/keyboard_shortcut_handler.dart';
import 'action_button_provider.dart';
import 'card_input_provider.dart';
import 'seat_provider.dart';

// ---------------------------------------------------------------------------
// Input-mode provider (mirrors handler state for UI consumption)
// ---------------------------------------------------------------------------

/// Exposes the current [InputMode] to widgets (e.g. mode indicator badge).
final inputModeProvider = StateProvider<InputMode>((ref) => InputMode.action);

// ---------------------------------------------------------------------------
// Selected seat provider (Tab/Shift+Tab navigation target)
// ---------------------------------------------------------------------------

/// Currently keyboard-selected seat number (1-based, null = none).
final selectedSeatProvider = StateProvider<int?>((ref) => null);

// ---------------------------------------------------------------------------
// Handler provider (singleton per CC window)
// ---------------------------------------------------------------------------

/// Creates and owns the [KeyboardShortcutHandler] instance.
///
/// Callbacks delegate to the appropriate Riverpod notifiers so that keyboard
/// events have the same effect as tapping buttons in the UI.
final keyboardShortcutProvider = Provider.autoDispose<KeyboardShortcutHandler>(
  (ref) {
    final handler = KeyboardShortcutHandler(
      // Action callback — forward to action button provider consumers.
      onAction: (CcAction action) {
        // The action is forwarded; the actual enabled-check happens at the
        // widget/command layer that reads actionButtonProvider.isEnabled().
        ref.read(_lastActionProvider.notifier).state = action;
      },

      // Card input callback — forward to card input notifier.
      onCardInput: (Suit suit, Rank rank) {
        final cardInput = ref.read(cardInputProvider.notifier);
        final state = ref.read(cardInputProvider);
        // Find first empty slot and fill it.
        for (var i = 0; i < state.slots.length; i++) {
          if (!state.slots[i].hasCard) {
            cardInput.manualSelect(i, suit, rank);
            break;
          }
        }
      },

      // Navigation callback — seat traversal via selectedSeatProvider.
      onNavigation: (NavAction nav) {
        final seats = ref.read(seatsProvider);
        final occupied = seats
            .where((s) => s.isOccupied)
            .map((s) => s.seatNo)
            .toList()
          ..sort();
        if (occupied.isEmpty) return;

        final current = ref.read(selectedSeatProvider);

        switch (nav) {
          case NavAction.nextSeat:
            if (current == null) {
              ref.read(selectedSeatProvider.notifier).state = occupied.first;
            } else {
              final idx = occupied.indexOf(current);
              final next = (idx + 1) % occupied.length;
              ref.read(selectedSeatProvider.notifier).state = occupied[next];
            }
          case NavAction.prevSeat:
            if (current == null) {
              ref.read(selectedSeatProvider.notifier).state = occupied.last;
            } else {
              final idx = occupied.indexOf(current);
              final prev = (idx - 1 + occupied.length) % occupied.length;
              ref.read(selectedSeatProvider.notifier).state = occupied[prev];
            }
          case NavAction.cancel:
            ref.read(selectedSeatProvider.notifier).state = null;
          case NavAction.confirm:
            // Confirm is context-dependent; no-op at provider level.
            break;
        }
      },

      // Numpad callback — bet-amount digit entry.
      onNumpad: (String value) {
        ref.read(_numpadBufferProvider.notifier).state = value;
      },
    );

    ref.onDispose(handler.dispose);

    return handler;
  },
);

// ---------------------------------------------------------------------------
// Internal state providers (consumed by UI / command layer)
// ---------------------------------------------------------------------------

/// Last action triggered by keyboard (consumed and cleared by command layer).
final _lastActionProvider = StateProvider<CcAction?>((ref) => null);

/// Publicly readable alias for the last keyboard-triggered action.
final lastKeyboardActionProvider = Provider<CcAction?>((ref) {
  return ref.watch(_lastActionProvider);
});

/// Last numpad key pressed (consumed and cleared by bet-amount widget).
final _numpadBufferProvider = StateProvider<String?>((ref) => null);

/// Publicly readable alias for the last numpad keystroke.
final lastNumpadKeyProvider = Provider<String?>((ref) {
  return ref.watch(_numpadBufferProvider);
});

/// Clear the last keyboard action after consumption.
void clearLastKeyboardAction(WidgetRef ref) {
  ref.read(_lastActionProvider.notifier).state = null;
}

/// Clear the last numpad key after consumption.
void clearLastNumpadKey(WidgetRef ref) {
  ref.read(_numpadBufferProvider.notifier).state = null;
}
