// ActionBadge — LAST action pill contract (Cycle 19 Wave 3 U3).
//
// 토큰 매핑 검증:
//   FOLD       → EbsOklch.err
//   CHECK/CALL → EbsOklch.ok
//   BET/RAISE  → EbsOklch.accent
//   ALL-IN     → EbsOklch.warn
//   none       → fg-3 dashed placeholder

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/action_badge.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';
import 'package:ebs_cc/models/enums/seat_status.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  group('ActionBadge label mapping', () {
    testWidgets('FOLD renders FOLD label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.fold));
      expect(find.text('FOLD'), findsOneWidget);
    });

    testWidgets('CHECK renders CHECK label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.check));
      expect(find.text('CHECK'), findsOneWidget);
    });

    testWidgets('CALL renders CALL label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.call));
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('BET renders BET label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.bet));
      expect(find.text('BET'), findsOneWidget);
    });

    testWidgets('RAISE renders RAISE label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.raise));
      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('ALL-IN renders ALL-IN label', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.allIn));
      expect(find.text('ALL-IN'), findsOneWidget);
    });

    testWidgets('none renders placeholder dash', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.none));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('custom label overrides default', (tester) async {
      await _pump(
        tester,
        const ActionBadge(type: ActionBadgeType.none, label: 'SIT OUT'),
      );
      expect(find.text('SIT OUT'), findsOneWidget);
    });
  });

  group('ActionBadge token mapping (spec)', () {
    test('FOLD tone == EbsOklch.err', () {
      expect(ActionBadgeType.fold.tone, EbsOklch.err);
    });
    test('CHECK tone == EbsOklch.ok', () {
      expect(ActionBadgeType.check.tone, EbsOklch.ok);
    });
    test('CALL tone == EbsOklch.ok', () {
      expect(ActionBadgeType.call.tone, EbsOklch.ok);
    });
    test('BET tone == EbsOklch.accent', () {
      expect(ActionBadgeType.bet.tone, EbsOklch.accent);
    });
    test('RAISE tone == EbsOklch.accent', () {
      expect(ActionBadgeType.raise.tone, EbsOklch.accent);
    });
    test('ALL-IN tone == EbsOklch.warn', () {
      expect(ActionBadgeType.allIn.tone, EbsOklch.warn);
    });
    test('none tone == EbsOklch.fg3', () {
      expect(ActionBadgeType.none.tone, EbsOklch.fg3);
    });
  });

  group('ActionBadge.fromActivity', () {
    testWidgets('folded → FOLD label', (tester) async {
      await _pump(tester, ActionBadge.fromActivity(PlayerActivity.folded));
      expect(find.text('FOLD'), findsOneWidget);
    });
    testWidgets('allIn → ALL-IN label', (tester) async {
      await _pump(tester, ActionBadge.fromActivity(PlayerActivity.allIn));
      expect(find.text('ALL-IN'), findsOneWidget);
    });
    testWidgets('sittingOut → SIT OUT label', (tester) async {
      await _pump(tester, ActionBadge.fromActivity(PlayerActivity.sittingOut));
      expect(find.text('SIT OUT'), findsOneWidget);
    });
    testWidgets('active → placeholder dash', (tester) async {
      await _pump(tester, ActionBadge.fromActivity(PlayerActivity.active));
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('ActionBadge onTap', () {
    testWidgets('tap forwards to callback', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ActionBadge(type: ActionBadgeType.fold, onTap: () => taps++),
      );
      await tester.tap(find.text('FOLD'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
