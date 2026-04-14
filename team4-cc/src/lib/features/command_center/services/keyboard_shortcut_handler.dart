// Keyboard shortcut system (BS-05-06).
//
// Two input modes:
//   ACTION     — default; single-key shortcuts trigger CC actions
//   CARD_INPUT — suit-then-rank 2-step card entry (1s suit timeout)
//
// System keys (Ctrl+Z, F11, Esc, Tab/Shift+Tab) work in both modes.
//
// FOCUS_MISMATCH_GUARD: 200ms suppression after window/widget focus gain
// prevents stale OS-level key events from triggering CC actions when the
// operator Alt+Tabs back into a multi-table CC instance.

import 'dart:async';

import 'package:flutter/services.dart';

import '../../../models/enums/card.dart';
import '../providers/action_button_provider.dart';

// ---------------------------------------------------------------------------
// Input mode
// ---------------------------------------------------------------------------

/// Active keyboard interpretation mode.
enum InputMode { action, cardInput }

// ---------------------------------------------------------------------------
// Navigation events
// ---------------------------------------------------------------------------

/// Navigation actions emitted by system keys.
enum NavAction { nextSeat, prevSeat, cancel, confirm }

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

/// Stateful keyboard shortcut processor.
///
/// Instantiate once per CC window and forward every [KeyEvent] from
/// a top-level [KeyboardListener] or [Focus] widget.
class KeyboardShortcutHandler {
  KeyboardShortcutHandler({
    required this.onAction,
    required this.onCardInput,
    required this.onNavigation,
    required this.onNumpad,
  });

  // -- callbacks ------------------------------------------------------------

  /// Fires when an action-mode shortcut maps to a [CcAction].
  final void Function(CcAction action) onAction;

  /// Fires when a complete card is entered (suit + rank).
  final void Function(Suit suit, Rank rank) onCardInput;

  /// Fires on Tab / Shift+Tab / Esc / Enter navigation.
  final void Function(NavAction nav) onNavigation;

  /// Fires on numpad digits, C (clear), Backspace, triple-zero.
  /// [value] is '0'-'9', 'C', 'BS', '000', or 'ENTER'.
  final void Function(String value) onNumpad;

  // -- state ----------------------------------------------------------------

  InputMode _mode = InputMode.action;

  /// Currently pending suit key awaiting a rank key (card-input mode).
  Suit? _pendingSuit;

  /// Auto-cancel timer for a pending suit (1 second).
  Timer? _suitTimeout;

  /// FOCUS_MISMATCH_GUARD timestamp.
  DateTime? _lastFocusGain;

  // -- public API -----------------------------------------------------------

  InputMode get mode => _mode;

  /// Call when the host widget/window gains focus.
  void onFocusGained() => _lastFocusGain = DateTime.now();

  /// Switch to card-input mode (e.g. when a card slot is tapped).
  void switchToCardInput() {
    _mode = InputMode.cardInput;
    _clearPendingSuit();
  }

  /// Return to action mode.
  void switchToAction() {
    _mode = InputMode.action;
    _clearPendingSuit();
  }

  /// Process a key event. Returns `true` if the event was consumed.
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_isFocusMismatchGuardActive) return false;

    // System keys are always active regardless of mode.
    if (_handleSystemKeys(event)) return true;

    return _mode == InputMode.action
        ? _handleActionMode(event)
        : _handleCardInputMode(event);
  }

  /// Release timers. Call when the handler is disposed.
  void dispose() {
    _suitTimeout?.cancel();
    _suitTimeout = null;
  }

  // -- focus guard ----------------------------------------------------------

  bool get _isFocusMismatchGuardActive =>
      _lastFocusGain != null &&
      DateTime.now().difference(_lastFocusGain!) <
          const Duration(milliseconds: 200);

  // -- system keys ----------------------------------------------------------

  bool _handleSystemKeys(KeyEvent event) {
    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Ctrl+Z → undo
    if (isCtrl && key == LogicalKeyboardKey.keyZ) {
      onAction(CcAction.undo);
      return true;
    }

    // F11 → fullscreen (handled upstream, but we consume it)
    if (key == LogicalKeyboardKey.f11) {
      return true;
    }

    // Esc → cancel / exit card-input mode
    if (key == LogicalKeyboardKey.escape) {
      if (_mode == InputMode.cardInput) {
        switchToAction();
      }
      onNavigation(NavAction.cancel);
      return true;
    }

    // Tab / Shift+Tab → seat navigation
    if (key == LogicalKeyboardKey.tab) {
      onNavigation(
        HardwareKeyboard.instance.isShiftPressed
            ? NavAction.prevSeat
            : NavAction.nextSeat,
      );
      return true;
    }

    // Enter → confirm
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_mode == InputMode.action) {
        onNumpad('ENTER');
      }
      onNavigation(NavAction.confirm);
      return true;
    }

    return false;
  }

  // -- action mode ----------------------------------------------------------

  bool _handleActionMode(KeyEvent event) {
    final key = event.logicalKey;

    // Action shortcuts (single letter).
    final actionMap = <LogicalKeyboardKey, CcAction>{
      LogicalKeyboardKey.keyN: CcAction.newHand,
      LogicalKeyboardKey.keyD: CcAction.deal,
      LogicalKeyboardKey.keyF: CcAction.fold,
      LogicalKeyboardKey.keyC: CcAction.checkCall,
      LogicalKeyboardKey.keyB: CcAction.betRaise,
      LogicalKeyboardKey.keyR: CcAction.betRaise,
      LogicalKeyboardKey.keyA: CcAction.allIn,
    };

    final action = actionMap[key];
    if (action != null) {
      onAction(action);
      return true;
    }

    // Numpad / digit keys for bet amount entry.
    if (_handleNumpadKey(event)) return true;

    // Space → confirm (same as Enter for bet amount)
    if (key == LogicalKeyboardKey.space) {
      onNumpad('ENTER');
      return true;
    }

    return false;
  }

  // -- card input mode ------------------------------------------------------

  bool _handleCardInputMode(KeyEvent event) {
    final key = event.logicalKey;

    // Suit keys: s/h/d/c → set pending suit with 1s timeout.
    final suitMap = <LogicalKeyboardKey, Suit>{
      LogicalKeyboardKey.keyS: Suit.spade,
      LogicalKeyboardKey.keyH: Suit.heart,
      LogicalKeyboardKey.keyD: Suit.diamond,
      LogicalKeyboardKey.keyC: Suit.club,
    };

    final suit = suitMap[key];
    if (suit != null) {
      _setPendingSuit(suit);
      return true;
    }

    // Rank keys: A/2-9/T/J/Q/K → complete card if suit is pending.
    final rankMap = <LogicalKeyboardKey, Rank>{
      LogicalKeyboardKey.keyA: Rank.ace,
      LogicalKeyboardKey.digit2: Rank.two,
      LogicalKeyboardKey.digit3: Rank.three,
      LogicalKeyboardKey.digit4: Rank.four,
      LogicalKeyboardKey.digit5: Rank.five,
      LogicalKeyboardKey.digit6: Rank.six,
      LogicalKeyboardKey.digit7: Rank.seven,
      LogicalKeyboardKey.digit8: Rank.eight,
      LogicalKeyboardKey.digit9: Rank.nine,
      LogicalKeyboardKey.keyT: Rank.ten,
      LogicalKeyboardKey.keyJ: Rank.jack,
      LogicalKeyboardKey.keyQ: Rank.queen,
      LogicalKeyboardKey.keyK: Rank.king,
    };

    final rank = rankMap[key];
    if (rank != null && _pendingSuit != null) {
      final completedSuit = _pendingSuit!;
      _clearPendingSuit();
      onCardInput(completedSuit, rank);
      return true;
    }

    return false;
  }

  // -- numpad helper --------------------------------------------------------

  bool _handleNumpadKey(KeyEvent event) {
    final key = event.logicalKey;

    // Digit row 0-9.
    final digitKeys = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
    };

    // Numpad 0-9.
    final numpadKeys = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    final digit = digitKeys[key] ?? numpadKeys[key];
    if (digit != null) {
      onNumpad(digit);
      return true;
    }

    // C key → clear in action mode numpad context.
    if (key == LogicalKeyboardKey.keyC) {
      onNumpad('C');
      return true;
    }

    // Backspace → delete last digit.
    if (key == LogicalKeyboardKey.backspace) {
      onNumpad('BS');
      return true;
    }

    return false;
  }

  // -- suit pending helpers -------------------------------------------------

  void _setPendingSuit(Suit suit) {
    _suitTimeout?.cancel();
    _pendingSuit = suit;
    _suitTimeout = Timer(const Duration(seconds: 1), () {
      _pendingSuit = null;
      _suitTimeout = null;
    });
  }

  void _clearPendingSuit() {
    _suitTimeout?.cancel();
    _suitTimeout = null;
    _pendingSuit = null;
  }
}
