// Card entity — Freezed DTO for WebSocket/REST serialization.
// Separate from enums/card.dart (Suit, Rank) to avoid naming collision.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_model.freezed.dart';
part 'card_model.g.dart';

@freezed
class CardModel with _$CardModel {
  const factory CardModel({
    required String suit, // "s", "h", "d", "c"
    required String rank, // "A", "2"-"9", "T", "J", "Q", "K"
  }) = _CardModel;

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);
}
