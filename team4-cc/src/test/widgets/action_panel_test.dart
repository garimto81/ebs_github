// ActionPanel widget tests (BS-05-02).
//
// Cycle 19 Wave 3 U4 — sync expectations with the zone-decomposed layout
// (`_UtilityZone` + `_MainZone` + `_LifecycleZone`) introduced in Cycle 18.
// Legacy 8-button grid labels ("NEW HAND" / standalone "DEAL") were replaced
// by FSM-driven lifecycle slot ("START HAND" / "IN PROGRESS" / "FINISH HAND"
// + compact "DEAL"). Tests now assert the current contract.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/table_state_provider.dart';
import 'package:ebs_cc/features/command_center/widgets/action_panel.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';
import 'package:ebs_cc/models/enums/table_fsm.dart';

/// Build a test widget with ActionPanel inside MaterialApp + ProviderScope.
Widget _buildTestWidget({
  required ProviderContainer container,
  void Function(CcAction action, {int? amount})? onAction,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        // Allow ample width so all three zones (utility/main/lifecycle) fit.
        body: SizedBox(
          width: 1200,
          height: 200,
          child: ActionPanel(onAction: onAction),
        ),
      ),
    ),
  );
}

void main() {
  group('ActionPanel widget — zone layout (Cycle 18+)', () {
    testWidgets('IDLE+LIVE renders 6-action surface', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.idle);

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // _LifecycleZone (IDLE) → "START HAND" + compact "DEAL".
      expect(find.text('START HAND'), findsOneWidget);
      expect(find.text('DEAL'), findsOneWidget);
      // _MainZone — street action quartet (FOLD/CHECK/BET/ALL-IN).
      expect(find.text('FOLD'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);
      expect(find.text('ALL-IN'), findsOneWidget);
      // _UtilityZone — UNDO + MISS DEAL.
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('MISS DEAL'), findsOneWidget);
    });

    testWidgets('disabled buttons are not tappable in IDLE', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.idle);

      final tappedAction = <CcAction>[];
      await tester.pumpWidget(_buildTestWidget(
        container: container,
        onAction: (action, {int? amount}) => tappedAction.add(action),
      ));
      await tester.pump();

      // FOLD disabled in IDLE.
      await tester.tap(find.text('FOLD'));
      await tester.pump();
      expect(tappedAction, isEmpty, reason: 'FOLD should be disabled in IDLE');

      // DEAL disabled in IDLE.
      await tester.tap(find.text('DEAL'));
      await tester.pump();
      expect(tappedAction, isEmpty, reason: 'DEAL should be disabled in IDLE');

      // START HAND (lifecycle slot, FSM=idle) → emits newHand.
      await tester.tap(find.text('START HAND'));
      await tester.pump();
      expect(tappedAction, [CcAction.newHand]);
    });

    testWidgets('dynamic label changes: CHECK↔CALL & BET↔RAISE',
        (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.preFlop);
      container.read(hasBetToMatchProvider.notifier).state = false;

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // No outstanding bet → CHECK / BET.
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);

      container.read(hasBetToMatchProvider.notifier).state = true;
      await tester.pump();

      // Outstanding bet → CALL / RAISE.
      expect(find.text('CALL'), findsOneWidget);
      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('PRE_FLOP renders "IN PROGRESS" lifecycle + 4 street actions',
        (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.preFlop);

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // _LifecycleZone (preFlop, non-idle / non-showdown) → "IN PROGRESS".
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('DEAL'), findsOneWidget);
      // Street action quartet remains present.
      expect(find.text('FOLD'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);
      expect(find.text('ALL-IN'), findsOneWidget);
      // Utility pair.
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('MISS DEAL'), findsOneWidget);
    });
  });
}
