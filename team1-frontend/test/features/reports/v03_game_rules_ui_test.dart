// Cycle 7 (v03 game rules) UI tests.
//
// Verifies:
//   1. Hand / HandPlayer freezed entities parse v03 fields and default
//      correctly when omitted (backward compat).
//   2. GameRulesBadges renders Ante / Straddle / Run It Twice badges
//      only when the value is meaningful (skips zero / null / RIT=1).
//   3. HandsSummaryList projects v03 row keys into a single "Rules"
//      DataColumn with compact badges.
//   4. HandDetail shows winner share "* N%" when runItTwiceCount > 1
//      and runItTwiceShare is set, and falls back to plain "*" otherwise.
//
// Run: flutter test test/features/reports/v03_game_rules_ui_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/reports/widgets/game_rules_badges.dart';
import 'package:ebs_lobby/features/reports/widgets/hand_detail.dart';
import 'package:ebs_lobby/features/reports/widgets/hands_summary_list.dart';
import 'package:ebs_lobby/models/entities/hand.dart';
import 'package:ebs_lobby/models/entities/hand_action.dart';
import 'package:ebs_lobby/models/entities/hand_player.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Hand _makeHand({
  int anteAmount = 0,
  int? straddleAmount,
  int runItTwiceCount = 1,
}) {
  return Hand(
    handId: 1,
    tableId: 1,
    handNumber: 42,
    gameType: 0,
    betStructure: 0,
    dealerSeat: 3,
    boardCards: 'Ah Kd Qc Js 10h',
    potTotal: 100000,
    sidePots: '[]',
    currentStreet: 'river',
    startedAt: '2026-05-12T10:00:00+00:00',
    endedAt: '2026-05-12T10:05:00+00:00',
    durationSec: 300,
    createdAt: '2026-05-12T10:00:00+00:00',
    anteAmount: anteAmount,
    straddleAmount: straddleAmount,
    runItTwiceCount: runItTwiceCount,
  );
}

HandPlayer _makePlayer({
  required int seatNo,
  required String name,
  required bool isWinner,
  double? share,
  int pnl = 0,
}) {
  return HandPlayer(
    id: seatNo,
    handId: 1,
    seatNo: seatNo,
    playerName: name,
    holeCards: 'Ah Kd',
    startStack: 50000,
    endStack: 50000 + pnl,
    isWinner: isWinner,
    pnl: pnl,
    vpip: true,
    pfr: true,
    runItTwiceShare: share,
  );
}

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

// ---------------------------------------------------------------------------
// 1. Entity parsing (backward compat + v03 fields)
// ---------------------------------------------------------------------------

void main() {
  group('Hand.fromJson (v03 fields)', () {
    test('omitted v03 fields → defaults (ante=0, straddle=null, RIT=1)', () {
      final hand = Hand.fromJson({
        'handId': 1,
        'tableId': 1,
        'handNumber': 1,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 3,
        'boardCards': 'Ah Kd',
        'potTotal': 100,
        'sidePots': '[]',
        'startedAt': '2026-05-12T10:00:00+00:00',
        'durationSec': 0,
        'createdAt': '2026-05-12T10:00:00+00:00',
      });
      expect(hand.anteAmount, 0);
      expect(hand.straddleAmount, isNull);
      expect(hand.runItTwiceCount, 1);
    });

    test('populated v03 fields parse correctly', () {
      final hand = Hand.fromJson({
        'handId': 1,
        'tableId': 1,
        'handNumber': 1,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 3,
        'boardCards': 'Ah Kd',
        'potTotal': 100,
        'sidePots': '[]',
        'startedAt': '2026-05-12T10:00:00+00:00',
        'durationSec': 0,
        'createdAt': '2026-05-12T10:00:00+00:00',
        'anteAmount': 200,
        'straddleAmount': 800,
        'runItTwiceCount': 2,
      });
      expect(hand.anteAmount, 200);
      expect(hand.straddleAmount, 800);
      expect(hand.runItTwiceCount, 2);
    });
  });

  group('HandPlayer.fromJson (v03 fields)', () {
    test('omitted runItTwiceShare → null', () {
      final hp = HandPlayer.fromJson({
        'id': 1,
        'handId': 1,
        'seatNo': 1,
        'playerName': 'Alice',
        'holeCards': 'Ah Kd',
        'startStack': 50000,
        'endStack': 50000,
        'isWinner': true,
        'pnl': 0,
        'vpip': true,
        'pfr': false,
      });
      expect(hp.runItTwiceShare, isNull);
    });

    test('runItTwiceShare=0.5 parses', () {
      final hp = HandPlayer.fromJson({
        'id': 1,
        'handId': 1,
        'seatNo': 1,
        'playerName': 'Alice',
        'holeCards': 'Ah Kd',
        'startStack': 50000,
        'endStack': 60000,
        'isWinner': true,
        'pnl': 10000,
        'vpip': true,
        'pfr': false,
        'runItTwiceShare': 0.5,
      });
      expect(hp.runItTwiceShare, 0.5);
    });
  });

  // -------------------------------------------------------------------------
  // 2. GameRulesBadges widget
  // -------------------------------------------------------------------------

  group('GameRulesBadges', () {
    testWidgets('renders nothing when no v03 rules apply', (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 0,
        straddleAmount: null,
        runItTwiceCount: 1,
      )));
      expect(find.textContaining('Ante'), findsNothing);
      expect(find.textContaining('Straddle'), findsNothing);
      expect(find.textContaining('Run It Twice'), findsNothing);
    });

    testWidgets('renders Ante badge when ante > 0', (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 200,
        straddleAmount: null,
        runItTwiceCount: 1,
      )));
      expect(find.textContaining('Ante 200'), findsOneWidget);
    });

    testWidgets('renders Straddle badge when straddleAmount > 0',
        (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 0,
        straddleAmount: 800,
        runItTwiceCount: 1,
      )));
      expect(find.textContaining('Straddle 800'), findsOneWidget);
    });

    testWidgets('renders RIT badge when runItTwiceCount > 1', (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 0,
        straddleAmount: null,
        runItTwiceCount: 2,
      )));
      expect(find.textContaining('Run It Twice'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
    });

    testWidgets('renders all three badges together', (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 200,
        straddleAmount: 800,
        runItTwiceCount: 2,
      )));
      expect(find.textContaining('Ante'), findsOneWidget);
      expect(find.textContaining('Straddle'), findsOneWidget);
      expect(find.textContaining('Run It Twice'), findsOneWidget);
    });

    testWidgets('compact mode renders short labels', (tester) async {
      await tester.pumpWidget(_wrap(const GameRulesBadges(
        anteAmount: 100,
        straddleAmount: 400,
        runItTwiceCount: 3,
        compact: true,
      )));
      // Compact A / S / RIT×N abbreviations.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('RIT×3'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 3. HandsSummaryList — projects v03 keys into a Rules column
  // -------------------------------------------------------------------------

  group('HandsSummaryList', () {
    testWidgets('hides Rules column when no row has v03 fields',
        (tester) async {
      final rows = [
        {'hand_number': 1, 'table_id': 5, 'pot_total': 1000},
        {'hand_number': 2, 'table_id': 5, 'pot_total': 2000},
      ];
      await tester.pumpWidget(_wrap(HandsSummaryList(rows: rows)));
      expect(find.text('Rules'), findsNothing);
      expect(find.text('Hand Number'), findsOneWidget);
    });

    testWidgets('shows Rules column with badges when v03 fields present',
        (tester) async {
      final rows = [
        {
          'hand_number': 1,
          'table_id': 5,
          'pot_total': 50000,
          'ante_amount': 200,
          'straddle_amount': null,
          'run_it_twice_count': 1,
        },
        {
          'hand_number': 2,
          'table_id': 5,
          'pot_total': 250000,
          'ante_amount': 200,
          'straddle_amount': 800,
          'run_it_twice_count': 2,
        },
      ];
      await tester.pumpWidget(_wrap(HandsSummaryList(rows: rows)));
      expect(find.text('Rules'), findsOneWidget);
      // Hand 1 has just ante → 1 badge ("A"). Hand 2 → 3 badges (A, S, RIT×2).
      expect(find.text('A'), findsNWidgets(2));
      expect(find.text('S'), findsOneWidget);
      expect(find.text('RIT×2'), findsOneWidget);
    });

    testWidgets('empty rows render fallback message', (tester) async {
      await tester
          .pumpWidget(_wrap(const HandsSummaryList(rows: [])));
      expect(find.text('No hands to display'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 4. HandDetail — run_it_twice split winner share
  // -------------------------------------------------------------------------

  group('HandDetail (run_it_twice split winner)', () {
    testWidgets('single run: winner shows bare star, no share %',
        (tester) async {
      final hand = _makeHand(runItTwiceCount: 1);
      final players = [
        _makePlayer(seatNo: 1, name: 'Alice', isWinner: true, pnl: 100000),
        _makePlayer(seatNo: 2, name: 'Bob', isWinner: false, pnl: -50000),
      ];
      await tester.pumpWidget(_wrap(HandDetail(
        hand: hand,
        players: players,
        actions: const <HandAction>[],
      )));
      expect(find.text('*'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      // No GameRulesBadges header rendered.
      expect(find.text('Winner (share)'), findsNothing);
    });

    testWidgets('multi run: each winner shows star + share percent',
        (tester) async {
      final hand = _makeHand(runItTwiceCount: 2);
      final players = [
        _makePlayer(
            seatNo: 1, name: 'Alice', isWinner: true, share: 0.5, pnl: 50000),
        _makePlayer(
            seatNo: 2, name: 'Bob', isWinner: true, share: 0.5, pnl: 50000),
        _makePlayer(seatNo: 3, name: 'Carol', isWinner: false, pnl: -100000),
      ];
      await tester.pumpWidget(_wrap(HandDetail(
        hand: hand,
        players: players,
        actions: const <HandAction>[],
      )));
      // Two winners, each "* 50%".
      expect(find.text('* 50%'), findsNWidgets(2));
      expect(find.text('Winner (share)'), findsOneWidget);
      // RIT badge in header.
      expect(find.textContaining('Run It Twice'), findsOneWidget);
    });

    testWidgets(
        'multi run, share missing: winner falls back to bare star',
        (tester) async {
      final hand = _makeHand(runItTwiceCount: 2);
      final players = [
        _makePlayer(seatNo: 1, name: 'Alice', isWinner: true, pnl: 100000),
      ];
      await tester.pumpWidget(_wrap(HandDetail(
        hand: hand,
        players: players,
        actions: const <HandAction>[],
      )));
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('header shows all v03 badges when ante + straddle + RIT set',
        (tester) async {
      final hand = _makeHand(
        anteAmount: 200,
        straddleAmount: 800,
        runItTwiceCount: 2,
      );
      final players = [
        _makePlayer(
            seatNo: 1, name: 'Alice', isWinner: true, share: 1.0, pnl: 50000),
      ];
      await tester.pumpWidget(_wrap(HandDetail(
        hand: hand,
        players: players,
        actions: const <HandAction>[],
      )));
      expect(find.textContaining('Ante 200'), findsOneWidget);
      expect(find.textContaining('Straddle 800'), findsOneWidget);
      expect(find.textContaining('Run It Twice'), findsOneWidget);
    });
  });
}
