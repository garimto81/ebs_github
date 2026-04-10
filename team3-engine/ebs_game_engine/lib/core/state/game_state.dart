import '../cards/card.dart';
import '../cards/deck.dart';
import '../rules/bet_limit.dart';
import '../rules/no_limit.dart';
import 'card_reveal_config.dart';
import 'seat.dart';
import 'pot.dart';
import 'betting_round.dart';

enum Street { setupHand, preflop, flop, turn, river, showdown, runItMultiple }

class GameState {
  final String sessionId;
  final String variantName;
  final List<Seat> seats;
  final List<Card> community;
  final Pot pot;
  final Street street;
  final int actionOn;
  final Deck deck;
  final BettingRound betting;
  final int dealerSeat;
  final int sbSeat;
  final int bbSeat;
  final int bbAmount;
  final bool handInProgress;

  // Hand tracking
  final int handNumber;

  // Ante configuration
  final int? anteAmount;
  final int? anteType; // 0-6 per BS-06-03

  // Straddle
  final bool straddleEnabled;
  final int? straddleSeat;

  // Card reveal
  final CardRevealConfig? revealConfig;
  final CanvasType canvasType;

  // Bomb Pot
  final bool bombPotEnabled;
  final int? bombPotAmount;

  // 7-2 Side Bet
  final bool sevenDeuceEnabled;
  final int? sevenDeuceAmount;

  // Run It Multiple
  final int? runItTimes;

  // Action timeout (ms, null = no timeout)
  final int? actionTimeoutMs;

  // Bet limit strategy (NL/FL/PL)
  final BetLimit? betLimit;

  GameState({
    required this.sessionId,
    required this.variantName,
    required this.seats,
    this.community = const [],
    Pot? pot,
    this.street = Street.preflop,
    this.actionOn = -1,
    required this.deck,
    BettingRound? betting,
    this.dealerSeat = 0,
    this.sbSeat = -1,
    this.bbSeat = -1,
    this.bbAmount = 0,
    this.handInProgress = false,
    this.handNumber = 0,
    this.anteAmount,
    this.anteType,
    this.straddleEnabled = false,
    this.straddleSeat,
    this.revealConfig,
    this.canvasType = CanvasType.broadcast,
    this.bombPotEnabled = false,
    this.bombPotAmount,
    this.sevenDeuceEnabled = false,
    this.sevenDeuceAmount,
    this.runItTimes,
    this.actionTimeoutMs,
    this.betLimit,
  })  : pot = pot ?? Pot(),
        betting = betting ?? BettingRound();

  GameState copyWith({
    List<Seat>? seats,
    List<Card>? community,
    Pot? pot,
    Street? street,
    int? actionOn,
    Deck? deck,
    BettingRound? betting,
    int? dealerSeat,
    int? sbSeat,
    int? bbSeat,
    int? bbAmount,
    bool? handInProgress,
    int? handNumber,
    int? anteAmount,
    int? anteType,
    bool? straddleEnabled,
    int? straddleSeat,
    CardRevealConfig? revealConfig,
    CanvasType? canvasType,
    bool? bombPotEnabled,
    int? bombPotAmount,
    bool? sevenDeuceEnabled,
    int? sevenDeuceAmount,
    int? runItTimes,
    int? actionTimeoutMs,
    BetLimit? betLimit,
  }) {
    return GameState(
      sessionId: sessionId,
      variantName: variantName,
      seats: seats ?? this.seats.map((s) => s.copy()).toList(),
      community: community ?? List.of(this.community),
      pot: pot ?? this.pot.copy(),
      street: street ?? this.street,
      actionOn: actionOn ?? this.actionOn,
      deck: deck ?? this.deck.copy(),
      betting: betting ?? this.betting.copy(),
      dealerSeat: dealerSeat ?? this.dealerSeat,
      sbSeat: sbSeat ?? this.sbSeat,
      bbSeat: bbSeat ?? this.bbSeat,
      bbAmount: bbAmount ?? this.bbAmount,
      handInProgress: handInProgress ?? this.handInProgress,
      handNumber: handNumber ?? this.handNumber,
      anteAmount: anteAmount ?? this.anteAmount,
      anteType: anteType ?? this.anteType,
      straddleEnabled: straddleEnabled ?? this.straddleEnabled,
      straddleSeat: straddleSeat ?? this.straddleSeat,
      revealConfig: revealConfig ?? this.revealConfig,
      canvasType: canvasType ?? this.canvasType,
      bombPotEnabled: bombPotEnabled ?? this.bombPotEnabled,
      bombPotAmount: bombPotAmount ?? this.bombPotAmount,
      sevenDeuceEnabled: sevenDeuceEnabled ?? this.sevenDeuceEnabled,
      sevenDeuceAmount: sevenDeuceAmount ?? this.sevenDeuceAmount,
      runItTimes: runItTimes ?? this.runItTimes,
      actionTimeoutMs: actionTimeoutMs ?? this.actionTimeoutMs,
      betLimit: betLimit ?? this.betLimit,
    );
  }

  List<Seat> get activePlayers =>
      seats.where((s) => s.isActive || s.isAllIn).toList();
  List<Seat> get actionablePlayers =>
      seats.where((s) => s.isActive).toList();
}
