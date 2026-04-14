// Hand entity — Freezed DTO for WebSocket/REST serialization.
// See BS-05-01-hand-lifecycle.md and DATA-04 §Hand.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_model.dart';
import 'hand_action.dart';
import 'pot.dart';

part 'hand.freezed.dart';
part 'hand.g.dart';

@freezed
class Hand with _$Hand {
  const factory Hand({
    required int id,
    required int handNumber,
    @Default('idle') String gamePhase, // HandFsm state name
    @Default([]) List<CardModel> communityCards,
    @Default([]) List<Pot> pots,
    int? actionOn, // seat number
    @Default([]) List<HandAction> actions,
    int? dealerSeat,
    int? winningSeat,
  }) = _Hand;

  factory Hand.fromJson(Map<String, dynamic> json) => _$HandFromJson(json);
}
