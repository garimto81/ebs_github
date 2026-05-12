// Player entity — Freezed DTO for WebSocket/REST serialization.
// See DATA-04 §Player entity.
//
// Cycle 17 (2026-05-13): lastAction 필드 추가 — Command_Center.md §16.9
// FieldEditor 7-grid (FOLD/CHECK/CALL/BET/RAISE/ALL_IN/Clear) cascade.
// ActionType enum (lib/models/enums/action_type.dart) 의 string 표현.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_model.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required int id,
    required String name,
    @Default('') String countryCode,
    @Default(0) int stack,
    @Default('active') String status, // active/folded/sittingOut/allIn
    @Default(0) int currentBet,
    String? position, // btn/sb/bb/utg/...
    @Default([]) List<CardModel> holeCards,
    String? avatarUrl,
    String? vipLevel,
    int? wsopId,
    // Cycle 17 — Action Indicator §16.9 cascade.
    // ActionType.{fold,check,bet,call,raise,allIn} 中 1 또는 null (Clear).
    // 시청자 화면 4 종 (fold/check/bet/raise) 만 visual indicator 표시,
    // call 은 visual_indicator=null (BET 매칭 통합), allIn 은 Player Dashboard emphasis.
    String? lastAction,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);
}
