import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand.freezed.dart';
part 'hand.g.dart';

@freezed
class Hand with _$Hand {
  const factory Hand({
    @JsonKey(name: 'handId') required int handId,
    @JsonKey(name: 'tableId') required int tableId,
    @JsonKey(name: 'handNumber') required int handNumber,
    @JsonKey(name: 'gameType') required int gameType,
    @JsonKey(name: 'betStructure') required int betStructure,
    @JsonKey(name: 'dealerSeat') required int dealerSeat,
    @JsonKey(name: 'boardCards') required String boardCards,
    @JsonKey(name: 'potTotal') required int potTotal,
    @JsonKey(name: 'sidePots') required String sidePots,
    @JsonKey(name: 'currentStreet') String? currentStreet,
    @JsonKey(name: 'startedAt') required String startedAt,
    @JsonKey(name: 'endedAt') String? endedAt,
    @JsonKey(name: 'durationSec') required int durationSec,
    @JsonKey(name: 'createdAt') required String createdAt,
  }) = _Hand;

  factory Hand.fromJson(Map<String, dynamic> json) => _$HandFromJson(json);
}
