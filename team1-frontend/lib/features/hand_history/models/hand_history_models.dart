// Hand History DTO 모델 — Cycle 21 W3 (Players_HandHistory_API.md v1.0.0).
//
// Reports 폐기 후 hand_history 독립 격상으로 신설된 DTO.
// 백엔드 응답 (camelCase via EbsBaseModel alias_generator=to_camel) 을 직접 매핑.
//
// 주의: lib/models/entities/hand.dart 는 `createdAt: required` 인데 API 응답
// (Players_HandHistory_API.md §2.3 + §2.4) 는 createdAt 을 미포함하므로
// 본 feature 는 자체 경량 DTO 를 정의한다. hand_players + hand_actions 는
// 기존 모델 (HandPlayer / HandAction) 을 재사용해도 되지만 cycle 21 spec 의
// nested 필드와 1:1 정합을 위해 별도 정의.

import 'dart:convert';

/// hands list item — Players_HandHistory_API.md §2.3 응답 본체.
class HandHistoryItem {
  final int handId;
  final int tableId;
  final int handNumber;
  final int gameType;
  final int betStructure;
  final int dealerSeat;
  final String boardCards; // JSON 문자열
  final int potTotal;
  final String sidePots; // JSON 문자열
  final String? currentStreet;
  final String startedAt;
  final String? endedAt;
  final int durationSec;
  final String? winnerPlayerName;

  const HandHistoryItem({
    required this.handId,
    required this.tableId,
    required this.handNumber,
    required this.gameType,
    required this.betStructure,
    required this.dealerSeat,
    required this.boardCards,
    required this.potTotal,
    required this.sidePots,
    this.currentStreet,
    required this.startedAt,
    this.endedAt,
    required this.durationSec,
    this.winnerPlayerName,
  });

  factory HandHistoryItem.fromJson(Map<String, dynamic> json) {
    return HandHistoryItem(
      handId: json['handId'] as int,
      tableId: json['tableId'] as int,
      handNumber: json['handNumber'] as int,
      gameType: json['gameType'] as int,
      betStructure: json['betStructure'] as int,
      dealerSeat: json['dealerSeat'] as int,
      boardCards: json['boardCards'] as String? ?? '[]',
      potTotal: json['potTotal'] as int,
      sidePots: json['sidePots'] as String? ?? '[]',
      currentStreet: json['currentStreet'] as String?,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      durationSec: json['durationSec'] as int,
      winnerPlayerName: json['winnerPlayerName'] as String?,
    );
  }

  /// boardCards JSON 문자열 → `List<String>` 변환 (예: `["As","Kh"]`).
  List<String> get boardCardList {
    if (boardCards.isEmpty) return const [];
    try {
      final decoded = jsonDecode(boardCards);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } on FormatException {
      // 빈 응답 또는 손상 → 빈 리스트 fallback (Detail 화면이 placeholder 표시).
    }
    return const [];
  }
}

/// cursor 페이지 응답 — `{items, nextCursor, hasMore}`.
class HandHistoryPage {
  final List<HandHistoryItem> items;
  final String? nextCursor;
  final bool hasMore;

  const HandHistoryPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory HandHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return HandHistoryPage(
      items: rawItems
          .map((e) => HandHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// hand detail nested player — §2.4 응답 hand_players 배열 element.
class HandHistoryPlayer {
  final int id;
  final int handId;
  final int seatNo;
  final int? playerId;
  final String playerName;
  final String holeCards; // RBAC 마스킹 가능 ("[]")
  final int startStack;
  final int endStack;
  final String? finalAction;
  final bool isWinner;
  final int pnl;
  final String? handRank;
  final double? winProbability;
  final bool vpip;
  final bool pfr;

  const HandHistoryPlayer({
    required this.id,
    required this.handId,
    required this.seatNo,
    this.playerId,
    required this.playerName,
    required this.holeCards,
    required this.startStack,
    required this.endStack,
    this.finalAction,
    required this.isWinner,
    required this.pnl,
    this.handRank,
    this.winProbability,
    required this.vpip,
    required this.pfr,
  });

  factory HandHistoryPlayer.fromJson(Map<String, dynamic> json) {
    return HandHistoryPlayer(
      id: json['id'] as int,
      handId: json['handId'] as int,
      seatNo: json['seatNo'] as int,
      playerId: json['playerId'] as int?,
      playerName: json['playerName'] as String? ?? '',
      holeCards: json['holeCards'] as String? ?? '[]',
      startStack: json['startStack'] as int? ?? 0,
      endStack: json['endStack'] as int? ?? 0,
      finalAction: json['finalAction'] as String?,
      isWinner: json['isWinner'] as bool? ?? false,
      pnl: json['pnl'] as int? ?? 0,
      handRank: json['handRank'] as String?,
      winProbability: (json['winProbability'] as num?)?.toDouble(),
      vpip: json['vpip'] as bool? ?? false,
      pfr: json['pfr'] as bool? ?? false,
    );
  }
}

/// hand detail nested action — §2.4 응답 hand_actions 배열 element.
class HandHistoryAction {
  final int id;
  final int handId;
  final int seatNo;
  final String actionType;
  final int actionAmount;
  final int? potAfter;
  final String street;
  final int actionOrder;
  final String? boardCards;
  final String? actionTime;

  const HandHistoryAction({
    required this.id,
    required this.handId,
    required this.seatNo,
    required this.actionType,
    required this.actionAmount,
    this.potAfter,
    required this.street,
    required this.actionOrder,
    this.boardCards,
    this.actionTime,
  });

  factory HandHistoryAction.fromJson(Map<String, dynamic> json) {
    return HandHistoryAction(
      id: json['id'] as int,
      handId: json['handId'] as int,
      seatNo: json['seatNo'] as int,
      actionType: json['actionType'] as String? ?? '',
      actionAmount: json['actionAmount'] as int? ?? 0,
      potAfter: json['potAfter'] as int?,
      street: json['street'] as String? ?? '',
      actionOrder: json['actionOrder'] as int? ?? 0,
      boardCards: json['boardCards'] as String?,
      actionTime: json['actionTime'] as String?,
    );
  }
}

/// hand detail 전체 응답 — §2.4 응답 본체.
class HandHistoryDetail {
  final int handId;
  final int tableId;
  final int handNumber;
  final int gameType;
  final int betStructure;
  final int dealerSeat;
  final String boardCards;
  final int potTotal;
  final String sidePots;
  final String? currentStreet;
  final String startedAt;
  final String? endedAt;
  final int durationSec;
  final List<HandHistoryPlayer> handPlayers;
  final List<HandHistoryAction> handActions;

  const HandHistoryDetail({
    required this.handId,
    required this.tableId,
    required this.handNumber,
    required this.gameType,
    required this.betStructure,
    required this.dealerSeat,
    required this.boardCards,
    required this.potTotal,
    required this.sidePots,
    this.currentStreet,
    required this.startedAt,
    this.endedAt,
    required this.durationSec,
    required this.handPlayers,
    required this.handActions,
  });

  factory HandHistoryDetail.fromJson(Map<String, dynamic> json) {
    final players = (json['handPlayers'] as List? ?? const [])
        .map((e) => HandHistoryPlayer.fromJson(e as Map<String, dynamic>))
        .toList();
    final actions = (json['handActions'] as List? ?? const [])
        .map((e) => HandHistoryAction.fromJson(e as Map<String, dynamic>))
        .toList();
    return HandHistoryDetail(
      handId: json['handId'] as int,
      tableId: json['tableId'] as int,
      handNumber: json['handNumber'] as int,
      gameType: json['gameType'] as int,
      betStructure: json['betStructure'] as int,
      dealerSeat: json['dealerSeat'] as int,
      boardCards: json['boardCards'] as String? ?? '[]',
      potTotal: json['potTotal'] as int,
      sidePots: json['sidePots'] as String? ?? '[]',
      currentStreet: json['currentStreet'] as String?,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      durationSec: json['durationSec'] as int,
      handPlayers: players,
      handActions: actions,
    );
  }
}

/// 리스트 화면 필터 상태. 진입 시 routing param 또는 URL query 로 prefill 가능.
class HandHistoryFilter {
  final int? eventId;
  final int? flightId;
  final int? tableId;
  final int? playerId;
  final bool showdownOnly;
  final String? dateFrom; // ISO8601
  final String? dateTo; // ISO8601

  const HandHistoryFilter({
    this.eventId,
    this.flightId,
    this.tableId,
    this.playerId,
    this.showdownOnly = false,
    this.dateFrom,
    this.dateTo,
  });

  HandHistoryFilter copyWith({
    Object? eventId = _sentinel,
    Object? flightId = _sentinel,
    Object? tableId = _sentinel,
    Object? playerId = _sentinel,
    bool? showdownOnly,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
  }) {
    return HandHistoryFilter(
      eventId: identical(eventId, _sentinel) ? this.eventId : eventId as int?,
      flightId:
          identical(flightId, _sentinel) ? this.flightId : flightId as int?,
      tableId: identical(tableId, _sentinel) ? this.tableId : tableId as int?,
      playerId:
          identical(playerId, _sentinel) ? this.playerId : playerId as int?,
      showdownOnly: showdownOnly ?? this.showdownOnly,
      dateFrom:
          identical(dateFrom, _sentinel) ? this.dateFrom : dateFrom as String?,
      dateTo: identical(dateTo, _sentinel) ? this.dateTo : dateTo as String?,
    );
  }

  Map<String, dynamic> toQueryParams({String? cursor, int limit = 50}) {
    final params = <String, dynamic>{'limit': limit};
    if (eventId != null) params['event_id'] = eventId;
    if (flightId != null) params['flight_id'] = flightId;
    if (tableId != null) params['table_id'] = tableId;
    if (playerId != null) params['player_id'] = playerId;
    if (showdownOnly) params['showdown_only'] = true;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (cursor != null) params['cursor'] = cursor;
    return params;
  }
}

// copyWith null-vs-omitted 구분을 위한 sentinel.
const Object _sentinel = Object();
