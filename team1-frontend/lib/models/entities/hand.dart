import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand.freezed.dart';
part 'hand.g.dart';

/// Hand entity — single poker hand record.
///
/// Cycle 7 (v03 game rules) extension:
///   - [anteAmount] — Ante per-player amount when game uses ante. 0 = no ante.
///   - [straddleAmount] — Straddle bet amount when posted. null = no straddle this hand.
///   - [runItTwiceCount] — Number of board runs when all-in players agreed to
///     "run it twice" (or more). 1 = single run (default), 2+ = split outcome.
///   - [runItTwiceCount] couples with [HandPlayer.runItTwiceShare] to express
///     pot share fractions (e.g. winner of 1/2 boards => share = 0.5).
///
/// All v03 fields are optional/defaulted for backward compatibility with
/// hands recorded before the v03 game-rules rollout.
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
    // v03 game-rules fields (Cycle 7, #329)
    @JsonKey(name: 'anteAmount') @Default(0) int anteAmount,
    @JsonKey(name: 'straddleAmount') int? straddleAmount,
    @JsonKey(name: 'runItTwiceCount') @Default(1) int runItTwiceCount,
  }) = _Hand;

  factory Hand.fromJson(Map<String, dynamic> json) => _$HandFromJson(json);
}
