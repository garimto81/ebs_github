import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand.freezed.dart';
part 'hand.g.dart';

@freezed
class Hand with _$Hand {
  const factory Hand({
    @JsonKey(name: 'hand_id') required int handId,
    @JsonKey(name: 'table_id') required int tableId,
    @JsonKey(name: 'hand_number') required int handNumber,
    @JsonKey(name: 'game_type') required int gameType,
    @JsonKey(name: 'bet_structure') required int betStructure,
    @JsonKey(name: 'dealer_seat') required int dealerSeat,
    @JsonKey(name: 'board_cards') required String boardCards,
    @JsonKey(name: 'pot_total') required int potTotal,
    @JsonKey(name: 'side_pots') required String sidePots,
    @JsonKey(name: 'current_street') String? currentStreet,
    @JsonKey(name: 'started_at') required String startedAt,
    @JsonKey(name: 'ended_at') String? endedAt,
    @JsonKey(name: 'duration_sec') required int durationSec,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Hand;

  factory Hand.fromJson(Map<String, dynamic> json) => _$HandFromJson(json);
}
