// Hand History 모델 fromJson 테스트 — Cycle 21 W3.
//
// 백엔드 (EbsBaseModel alias_generator=to_camel) 응답을 그대로 입력하여
// DTO 파싱 정확성 검증. Players_HandHistory_API.md §2.3, §2.4 spec 예시 사용.

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/hand_history/models/hand_history_models.dart';

void main() {
  group('HandHistoryItem.fromJson', () {
    test('spec §2.3 example 매핑', () {
      final json = {
        'handId': 500,
        'tableId': 124,
        'handNumber': 47,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 3,
        'boardCards': '["As","Kh","Qd","Js","10c"]',
        'potTotal': 25000,
        'sidePots': '[]',
        'currentStreet': null,
        'startedAt': '2026-05-13T07:30:00Z',
        'endedAt': '2026-05-13T07:32:15Z',
        'durationSec': 135,
        'winnerPlayerName': 'John Smith',
      };

      final item = HandHistoryItem.fromJson(json);

      expect(item.handId, 500);
      expect(item.tableId, 124);
      expect(item.handNumber, 47);
      expect(item.potTotal, 25000);
      expect(item.winnerPlayerName, 'John Smith');
      expect(item.boardCardList, ['As', 'Kh', 'Qd', 'Js', '10c']);
    });

    test('boardCards 빈 문자열 → 빈 리스트', () {
      final json = {
        'handId': 1,
        'tableId': 1,
        'handNumber': 1,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 1,
        'boardCards': '',
        'potTotal': 0,
        'sidePots': '[]',
        'startedAt': '2026-05-13T07:00:00Z',
        'durationSec': 0,
      };

      final item = HandHistoryItem.fromJson(json);
      expect(item.boardCardList, isEmpty);
    });
  });

  group('HandHistoryPage.fromJson', () {
    test('items + nextCursor + hasMore', () {
      final json = {
        'items': [
          {
            'handId': 500,
            'tableId': 124,
            'handNumber': 47,
            'gameType': 0,
            'betStructure': 0,
            'dealerSeat': 3,
            'boardCards': '[]',
            'potTotal': 25000,
            'sidePots': '[]',
            'startedAt': '2026-05-13T07:30:00Z',
            'durationSec': 135,
          },
        ],
        'nextCursor': 'eyJoYW5kX2lkIjo1NTB9',
        'hasMore': true,
      };

      final page = HandHistoryPage.fromJson(json);
      expect(page.items.length, 1);
      expect(page.items.first.handId, 500);
      expect(page.nextCursor, 'eyJoYW5kX2lkIjo1NTB9');
      expect(page.hasMore, isTrue);
    });

    test('빈 items + null cursor + hasMore=false', () {
      final json = {
        'items': [],
        'nextCursor': null,
        'hasMore': false,
      };
      final page = HandHistoryPage.fromJson(json);
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
    });
  });

  group('HandHistoryDetail.fromJson', () {
    test('spec §2.4 nested 매핑', () {
      final json = {
        'handId': 500,
        'tableId': 124,
        'handNumber': 47,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 3,
        'boardCards': '["As","Kh","Qd","Js","10c"]',
        'potTotal': 25000,
        'sidePots': '[]',
        'startedAt': '2026-05-13T07:30:00Z',
        'endedAt': '2026-05-13T07:32:15Z',
        'durationSec': 135,
        'handPlayers': [
          {
            'id': 2001,
            'handId': 500,
            'seatNo': 1,
            'playerId': 100,
            'playerName': 'John Smith',
            'holeCards': '["Ah","As"]',
            'startStack': 50000,
            'endStack': 65000,
            'finalAction': 'showdown_win',
            'isWinner': true,
            'pnl': 15000,
            'handRank': 'Royal Flush',
            'winProbability': 0.98,
            'vpip': true,
            'pfr': true,
          },
        ],
        'handActions': [
          {
            'id': 9001,
            'handId': 500,
            'seatNo': 1,
            'actionType': 'raise',
            'actionAmount': 1200,
            'potAfter': 1800,
            'street': 'preflop',
            'actionOrder': 1,
            'boardCards': null,
            'actionTime': '2026-05-13T07:30:15Z',
          },
        ],
      };

      final d = HandHistoryDetail.fromJson(json);
      expect(d.handId, 500);
      expect(d.handPlayers.length, 1);
      expect(d.handPlayers.first.isWinner, isTrue);
      expect(d.handPlayers.first.handRank, 'Royal Flush');
      expect(d.handActions.length, 1);
      expect(d.handActions.first.actionType, 'raise');
      expect(d.handActions.first.potAfter, 1800);
    });

    test('hole_cards 마스킹 (RBAC viewer) → "[]" 입력', () {
      final json = {
        'handId': 1,
        'tableId': 1,
        'handNumber': 1,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 1,
        'boardCards': '[]',
        'potTotal': 0,
        'sidePots': '[]',
        'startedAt': '2026-05-13T07:00:00Z',
        'durationSec': 0,
        'handPlayers': [
          {
            'id': 1,
            'handId': 1,
            'seatNo': 1,
            'playerName': 'Viewer Masked',
            'holeCards': '[]',
            'startStack': 100,
            'endStack': 100,
            'isWinner': false,
            'pnl': 0,
            'vpip': false,
            'pfr': false,
          },
        ],
        'handActions': [],
      };

      final d = HandHistoryDetail.fromJson(json);
      expect(d.handPlayers.first.holeCards, '[]');
    });
  });

  group('HandHistoryFilter.toQueryParams', () {
    test('snake_case key + cursor + limit', () {
      const filter = HandHistoryFilter(
        eventId: 42,
        tableId: 124,
        playerId: 100,
        showdownOnly: true,
        dateFrom: '2026-05-13T00:00:00Z',
      );
      final params =
          filter.toQueryParams(cursor: 'eyJoYW5kX2lkIjo1MDB9', limit: 30);
      expect(params['event_id'], 42);
      expect(params['table_id'], 124);
      expect(params['player_id'], 100);
      expect(params['showdown_only'], true);
      expect(params['date_from'], '2026-05-13T00:00:00Z');
      expect(params['cursor'], 'eyJoYW5kX2lkIjo1MDB9');
      expect(params['limit'], 30);
      expect(params.containsKey('flight_id'), isFalse);
      expect(params.containsKey('date_to'), isFalse);
    });

    test('showdownOnly=false → query 에 미포함 (BO 기본값과 동일)', () {
      const filter = HandHistoryFilter();
      final params = filter.toQueryParams();
      expect(params.containsKey('showdown_only'), isFalse);
      expect(params['limit'], 50);
    });
  });
}
