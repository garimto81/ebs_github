import '../cards/card.dart';
import '../cards/deck.dart';
import 'seat.dart';
import 'pot.dart';
import 'betting_round.dart';

enum Street { preflop, flop, turn, river, showdown }

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
    );
  }

  List<Seat> get activePlayers =>
      seats.where((s) => s.isActive || s.isAllIn).toList();
  List<Seat> get actionablePlayers =>
      seats.where((s) => s.isActive).toList();
}
