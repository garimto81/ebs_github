// SG-002 Stub Engine — Demo Mode fallback (in-process stub engine).
//
// When the real Game Engine harness (http://localhost:8080) is unreachable,
// the CC falls back to this in-process stub engine so UI/UX can be
// demonstrated without engine infrastructure.
//
// Scope (SG-002 §4 fallback): basic hand progression only
//   • Pre-flop/Flop/Turn/River fixed sequence
//   • Random hole cards + community cards
//   • Fake OutputEvent emission (subset of 21 types)
//
// team4 session TODO markers:
//   [TODO-T4-001] real RNG with proper deck enforcement
//   [TODO-T4-002] integrate with engine_connection_provider state machine
//   [TODO-T4-003] stream OutputEvent to Overlay consumer
//   [TODO-T4-004] persist stub hand to BO for replay consistency (optional)

import 'dart:async';
import 'dart:math' as math;

import '../../../data/remote/engine_client.dart';

/// In-process stub engine used by Demo Mode when real engine is offline.
///
/// Not a full implementation — emulates just enough for prototype/demo.
class StubEngine {
  StubEngine({math.Random? random})
      : _random = random ?? math.Random();

  final math.Random _random;
  final _eventController = StreamController<StubOutputEvent>.broadcast();

  /// Stream of OutputEvent-like messages (subset of real 21 types).
  Stream<StubOutputEvent> get events => _eventController.stream;

  /// Begin a new hand with [seatCount] players (2~10).
  ///
  /// Emits: hand_start → holecards_revealed → ... → hand_end
  Future<void> startHand({required int seatCount}) async {
    assert(seatCount >= 2 && seatCount <= 10, 'seat count must be 2..10');
    _emit(StubOutputEvent.handStart);

    final deck = _shuffledDeck();
    final holeCards = <int, List<String>>{};
    for (var seat = 0; seat < seatCount; seat++) {
      holeCards[seat] = [deck.removeLast(), deck.removeLast()];
    }
    _emit(StubOutputEvent.holecardsRevealed(holeCards));

    // Pre-flop → Flop → Turn → River (no betting simulation in stub)
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final flop = [deck.removeLast(), deck.removeLast(), deck.removeLast()];
    _emit(StubOutputEvent.communityBoardUpdated(flop));

    await Future<void>.delayed(const Duration(milliseconds: 400));
    final turn = [...flop, deck.removeLast()];
    _emit(StubOutputEvent.communityBoardUpdated(turn));

    await Future<void>.delayed(const Duration(milliseconds: 400));
    final river = [...turn, deck.removeLast()];
    _emit(StubOutputEvent.communityBoardUpdated(river));

    // Showdown (winner = random seat for stub)
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _emit(StubOutputEvent.showdownReveal(_random.nextInt(seatCount)));
    _emit(StubOutputEvent.handEnd);
  }

  List<String> _shuffledDeck() {
    const ranks = [
      'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2',
    ];
    const suits = ['S', 'H', 'D', 'C'];
    final deck = <String>[];
    for (final r in ranks) {
      for (final s in suits) {
        deck.add('$r$s');
      }
    }
    deck.shuffle(_random);
    return deck;
  }

  void _emit(StubOutputEvent event) => _eventController.add(event);

  Future<void> dispose() async {
    await _eventController.close();
  }
}

/// Minimal subset of OutputEvent used in Demo Mode.
///
/// Real event catalog: docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md §6.0 (21 types).
sealed class StubOutputEvent {
  const StubOutputEvent();

  static const handStart = _HandStart();
  static const handEnd = _HandEnd();

  const factory StubOutputEvent.holecardsRevealed(
    Map<int, List<String>> cards,
  ) = _HolecardsRevealed;

  const factory StubOutputEvent.communityBoardUpdated(
    List<String> board,
  ) = _CommunityBoardUpdated;

  const factory StubOutputEvent.showdownReveal(int winnerSeat) = _ShowdownReveal;

  /// Event type matching real engine's OutputEvent catalog.
  String get eventType;
}

class _HandStart extends StubOutputEvent {
  const _HandStart();
  @override
  String get eventType => 'hand_start';
}

class _HandEnd extends StubOutputEvent {
  const _HandEnd();
  @override
  String get eventType => 'hand_end';
}

class _HolecardsRevealed extends StubOutputEvent {
  const _HolecardsRevealed(this.cards);
  final Map<int, List<String>> cards;
  @override
  String get eventType => 'holecards_revealed';
}

class _CommunityBoardUpdated extends StubOutputEvent {
  const _CommunityBoardUpdated(this.board);
  final List<String> board;
  @override
  String get eventType => 'community_board_updated';
}

class _ShowdownReveal extends StubOutputEvent {
  const _ShowdownReveal(this.winnerSeat);
  final int winnerSeat;
  @override
  String get eventType => 'showdown_reveal';
}

/// Helper: ENGINE_URL resolution (mirror of EngineClient.kDefaultEngineUrl).
///
/// Used by engine_connection_provider to determine initial target.
String get kEngineUrl => EngineClient.kDefaultEngineUrl;
