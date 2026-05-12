// Golden screenshot test — v03 game-rules UI (Cycle 7, #329).
//
// Generates PNG snapshots of the new badges + handHistory split-winner UI.
// Output is consumed by the multi-session orchestrator's KPI artifact
// (test-results/v01-lobby/cycle7/*.png).
//
// Update goldens with:
//   flutter test --update-goldens test/features/reports/v03_game_rules_ui_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/reports/widgets/game_rules_badges.dart';
import 'package:ebs_lobby/features/reports/widgets/hand_detail.dart';
import 'package:ebs_lobby/features/reports/widgets/hands_summary_list.dart';
import 'package:ebs_lobby/models/entities/hand.dart';
import 'package:ebs_lobby/models/entities/hand_action.dart';
import 'package:ebs_lobby/models/entities/hand_player.dart';

Hand _makeHand({
  int anteAmount = 0,
  int? straddleAmount,
  int runItTwiceCount = 1,
}) {
  return Hand(
    handId: 1,
    tableId: 5,
    handNumber: 42,
    gameType: 0,
    betStructure: 0,
    dealerSeat: 3,
    boardCards: 'Ah Kd Qc Js 10h',
    potTotal: 250000,
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
    handRank: isWinner ? 'Two Pair' : null,
    vpip: true,
    pfr: true,
    runItTwiceShare: share,
  );
}

Widget _wrap(Widget child, {double width = 800, double height = 400}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('cycle7_badges_full', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 120));
    await tester.pumpWidget(_wrap(
      const Padding(
        padding: EdgeInsets.all(16),
        child: GameRulesBadges(
          anteAmount: 200,
          straddleAmount: 800,
          runItTwiceCount: 2,
        ),
      ),
      width: 640,
      height: 120,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/cycle7_badges_full.png'),
    );
  });

  testWidgets('cycle7_hands_summary_with_badges', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 420));
    final rows = [
      {
        'hand_number': 41,
        'table_id': 5,
        'pot_total': 50000,
        'ante_amount': 0,
        'straddle_amount': null,
        'run_it_twice_count': 1,
      },
      {
        'hand_number': 42,
        'table_id': 5,
        'pot_total': 150000,
        'ante_amount': 200,
        'straddle_amount': null,
        'run_it_twice_count': 1,
      },
      {
        'hand_number': 43,
        'table_id': 5,
        'pot_total': 250000,
        'ante_amount': 200,
        'straddle_amount': 800,
        'run_it_twice_count': 2,
      },
    ];
    await tester.pumpWidget(_wrap(
      HandsSummaryList(rows: rows),
      width: 1024,
      height: 420,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/cycle7_hands_summary_with_badges.png'),
    );
  });

  testWidgets('cycle7_handhistory_split_winner', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 480));
    final hand = _makeHand(
      anteAmount: 200,
      straddleAmount: 800,
      runItTwiceCount: 2,
    );
    final players = [
      _makePlayer(
          seatNo: 1, name: 'Alice', isWinner: true, share: 0.5, pnl: 125000),
      _makePlayer(
          seatNo: 4, name: 'Bob', isWinner: true, share: 0.5, pnl: 125000),
      _makePlayer(seatNo: 7, name: 'Carol', isWinner: false, pnl: -250000),
    ];
    await tester.pumpWidget(_wrap(
      HandDetail(hand: hand, players: players, actions: const <HandAction>[]),
      width: 900,
      height: 480,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/cycle7_handhistory_split_winner.png'),
    );
  });
}
