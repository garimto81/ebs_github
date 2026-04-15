// Card input mode FSM (BS-05-04).
//
// Two modes:
//   ACTION  — normal CC operation, action buttons active
//   CARD_INPUT — RFID/manual card entry, seat slots highlighted
//
// Each card slot has its own state machine:
//   EMPTY -> DETECTING -> DEALT (success) or FALLBACK (timeout) or WRONG_CARD (mismatch)
//
// 5-second RFID fallback: if no card detected within 5s, slot -> FALLBACK
// and manual composite selector appears (suit + rank).
//
// Duplicate card prevention: no two slots can have the same card in a hand.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/card.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// CC input mode.
enum CardInputMode { action, cardInput }

/// Per-slot state.
enum CardSlotStatus { empty, detecting, dealt, fallback, wrongCard }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// A single card slot (one hole card position).
class CardSlot {
  const CardSlot({
    this.status = CardSlotStatus.empty,
    this.suit,
    this.rank,
  });

  final CardSlotStatus status;
  final Suit? suit;
  final Rank? rank;

  bool get hasCard => suit != null && rank != null;

  String get label {
    if (!hasCard) return '--';
    return '${rank!.name}${suit!.name[0]}';
  }

  CardSlot copyWith({
    CardSlotStatus? status,
    Suit? suit,
    Rank? rank,
    bool clearCard = false,
  }) =>
      CardSlot(
        status: status ?? this.status,
        suit: clearCard ? null : (suit ?? this.suit),
        rank: clearCard ? null : (rank ?? this.rank),
      );
}

/// Full card input state.
class CardInputState {
  const CardInputState({
    this.mode = CardInputMode.action,
    this.targetSeatNo,
    this.slots = const [CardSlot(), CardSlot()],
    this.dealtCards = const {},
  });

  /// Current input mode.
  final CardInputMode mode;

  /// Which seat is receiving cards (null when mode == action).
  final int? targetSeatNo;

  /// Card slots for the target seat (typically 2 for Hold'em).
  final List<CardSlot> slots;

  /// Set of all dealt card keys ("Ah", "Ks") in this hand for dupe prevention.
  final Set<String> dealtCards;

  CardInputState copyWith({
    CardInputMode? mode,
    int? targetSeatNo,
    bool clearTarget = false,
    List<CardSlot>? slots,
    Set<String>? dealtCards,
  }) =>
      CardInputState(
        mode: mode ?? this.mode,
        targetSeatNo: clearTarget ? null : (targetSeatNo ?? this.targetSeatNo),
        slots: slots ?? this.slots,
        dealtCards: dealtCards ?? this.dealtCards,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// RFID fallback timeout duration (Manual_Card_Input.md §6.5).
const _rfidTimeoutDuration = Duration(seconds: 5);

/// WRONG_CARD auto-revert window (Manual_Card_Input.md §6.5).
const _wrongCardRevertDuration = Duration(seconds: 1);

class CardInputNotifier extends StateNotifier<CardInputState> {
  CardInputNotifier() : super(const CardInputState());

  final Map<int, Timer> _slotTimers = {};
  final Map<int, Timer> _wrongCardTimers = {};

  /// Enter card input mode for [seatNo].
  void enterCardInput(int seatNo, {int slotCount = 2}) {
    _cancelAllTimers();
    state = CardInputState(
      mode: CardInputMode.cardInput,
      targetSeatNo: seatNo,
      slots: List.generate(slotCount, (_) => const CardSlot()),
      dealtCards: state.dealtCards, // preserve across seats
    );
  }

  /// Exit card input mode, return to action mode.
  void exitCardInput() {
    _cancelAllTimers();
    state = state.copyWith(
      mode: CardInputMode.action,
      clearTarget: true,
      slots: const [CardSlot(), CardSlot()],
    );
  }

  /// Start RFID detection for slot [index]. Sets DETECTING + 5s timeout.
  void startDetecting(int index) {
    _cancelTimer(index);
    _cancelWrongTimer(index);
    _updateSlot(index, (s) => s.copyWith(status: CardSlotStatus.detecting));

    _slotTimers[index] = Timer(_rfidTimeoutDuration, () {
      if (mounted) {
        _updateSlot(
            index, (s) => s.copyWith(status: CardSlotStatus.fallback));
      }
    });
  }

  /// Skip the 5-second wait and force [index] into FALLBACK immediately.
  ///
  /// Called when the operator taps a slot while the RFID reader is in a
  /// failed state — Manual_Fallback.md §5.5 maps `disconnected` /
  /// `connectionFailed` / `reconnecting` to "즉시 FALLBACK".
  void requestManualForSlot(int index) {
    _cancelTimer(index);
    _cancelWrongTimer(index);
    _updateSlot(index, (s) => s.copyWith(status: CardSlotStatus.fallback));
  }

  /// RFID detected a card for slot [index].
  void cardDetected(int index, Suit suit, Rank rank) {
    _cancelTimer(index);

    final key = _cardKey(suit, rank);

    // Duplicate check — Manual_Card_Input.md §6.5 WRONG_CARD 1s revert.
    if (state.dealtCards.contains(key)) {
      final prevStatus = state.slots[index].status;
      _updateSlot(index, (s) => s.copyWith(status: CardSlotStatus.wrongCard));
      _cancelWrongTimer(index);
      _wrongCardTimers[index] = Timer(_wrongCardRevertDuration, () {
        if (!mounted) return;
        // Revert to the prior non-error status (typically DETECTING or
        // EMPTY) so the operator can immediately retry.
        final revertTo = prevStatus == CardSlotStatus.wrongCard
            ? CardSlotStatus.empty
            : prevStatus;
        _updateSlot(index, (s) => s.copyWith(status: revertTo));
      });
      return;
    }

    _updateSlot(
      index,
      (s) => s.copyWith(status: CardSlotStatus.dealt, suit: suit, rank: rank),
    );

    // Track dealt card.
    state = state.copyWith(dealtCards: {...state.dealtCards, key});
  }

  /// Manual composite card selection (suit + rank) for slot [index].
  void manualSelect(int index, Suit suit, Rank rank) {
    cardDetected(index, suit, rank); // same logic
  }

  /// Clear a specific slot.
  void clearSlot(int index) {
    final slot = state.slots[index];
    if (slot.hasCard) {
      final key = _cardKey(slot.suit!, slot.rank!);
      final next = Set<String>.from(state.dealtCards)..remove(key);
      state = state.copyWith(dealtCards: next);
    }
    _updateSlot(index, (_) => const CardSlot());
  }

  /// Reset all dealt cards (new hand).
  void resetHand() {
    _cancelAllTimers();
    state = const CardInputState();
  }

  // -- helpers ---------------------------------------------------------------

  void _updateSlot(int index, CardSlot Function(CardSlot) fn) {
    final slots = List<CardSlot>.from(state.slots);
    slots[index] = fn(slots[index]);
    state = state.copyWith(slots: slots);
  }

  String _cardKey(Suit suit, Rank rank) => '${rank.name}${suit.name}';

  void _cancelTimer(int index) {
    _slotTimers[index]?.cancel();
    _slotTimers.remove(index);
  }

  void _cancelWrongTimer(int index) {
    _wrongCardTimers[index]?.cancel();
    _wrongCardTimers.remove(index);
  }

  void _cancelAllTimers() {
    for (final t in _slotTimers.values) {
      t.cancel();
    }
    _slotTimers.clear();
    for (final t in _wrongCardTimers.values) {
      t.cancel();
    }
    _wrongCardTimers.clear();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final cardInputProvider =
    StateNotifierProvider<CardInputNotifier, CardInputState>(
  (ref) => CardInputNotifier(),
);

/// Derived: whether we are in card input mode.
final isCardInputModeProvider = Provider<bool>((ref) {
  return ref.watch(cardInputProvider).mode == CardInputMode.cardInput;
});
