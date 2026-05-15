// ActionBadge — LAST action pill contract (Cycle 19 Wave 3 U3).
//
// 토큰 매핑 검증 (HTML mockup SSOT 정합 — PR #480 이후):
//   FOLD       → EbsOklch.fg2    (gray, HTML #616161)
//   CHECK/CALL → EbsOklch.info   (blue, HTML #1976d2)
//   BET        → EbsOklch.accent (amber, HTML #f9a825)
//   RAISE      → EbsOklch.err    (red, HTML #e53935)
//   ALL-IN     → EbsOklch.warn   (gold)
//   none       → fg-3 placeholder
//
// Cycle 21 (residual-drift) — 추가 검증:
//   CHECK pulse bar  → kActionBadgePulseBarKey 위젯 존재
//   CALL dashed      → kActionBadgeCallDashedKey CustomPaint 존재

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

  group('ActionBadge token mapping (HTML SSOT — #480 정합)', () {
    test('FOLD tone == EbsOklch.fg2', () {
      expect(ActionBadgeType.fold.tone, EbsOklch.fg2);
    });
    test('CHECK tone == EbsOklch.info', () {
      expect(ActionBadgeType.check.tone, EbsOklch.info);
    });
    test('CALL tone == EbsOklch.info', () {
      expect(ActionBadgeType.call.tone, EbsOklch.info);
    });
    test('BET tone == EbsOklch.accent', () {
      expect(ActionBadgeType.bet.tone, EbsOklch.accent);
    });
    test('RAISE tone == EbsOklch.err', () {
      expect(ActionBadgeType.raise.tone, EbsOklch.err);
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

  // ──────────────────────────────────────────────────────────────────
  // Cycle 21 residual-drift: CHECK pulse + CALL dashed border
  // ──────────────────────────────────────────────────────────────────

  group('CHECK pulse animation (drift #1)', () {
    testWidgets('CHECK badge has pulse bar widget', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.check));
      await tester.pump();
      expect(find.byKey(kActionBadgePulseBarKey), findsOneWidget);
    });

    testWidgets('non-CHECK badges do NOT have pulse bar', (tester) async {
      for (final t in [
        ActionBadgeType.fold,
        ActionBadgeType.call,
        ActionBadgeType.bet,
        ActionBadgeType.raise,
        ActionBadgeType.allIn,
        ActionBadgeType.none,
      ]) {
        await _pump(tester, ActionBadge(type: t));
        await tester.pump();
        expect(
          find.byKey(kActionBadgePulseBarKey),
          findsNothing,
          reason: '$t should not have pulse bar',
        );
      }
    });

    testWidgets('CHECK pulse animates without crash over 1.4s', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(kActionBadgePulseBarKey), findsOneWidget);
    });
  });

  group('CALL dashed border / visual_indicator=null (drift #3)', () {
    testWidgets('CALL badge has dashed border CustomPaint', (tester) async {
      await _pump(tester, const ActionBadge(type: ActionBadgeType.call));
      await tester.pump();
      expect(find.byKey(kActionBadgeCallDashedKey), findsOneWidget);
    });

    testWidgets('non-CALL badges do NOT have dashed border key', (tester) async {
      for (final t in [
        ActionBadgeType.fold,
        ActionBadgeType.check,
        ActionBadgeType.bet,
        ActionBadgeType.raise,
        ActionBadgeType.allIn,
        ActionBadgeType.none,
      ]) {
        await _pump(tester, ActionBadge(type: t));
        await tester.pump();
        expect(
          find.byKey(kActionBadgeCallDashedKey),
          findsNothing,
          reason: '$t should not have dashed border',
        );
      }
    });
  });
}
