// ActionPanel widget tests (BS-05-02).

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
        body: ActionPanel(onAction: onAction),
      ),
    ),
  );
}

void main() {
  group('ActionPanel widget', () {
    testWidgets('all 8 buttons render in IDLE+LIVE state', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.idle);

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // 8 buttons: NEW HAND, DEAL, FOLD, CHECK, BET, ALL-IN, UNDO, MISS DEAL
      expect(find.text('NEW HAND'), findsOneWidget);
      expect(find.text('DEAL'), findsOneWidget);
      expect(find.text('FOLD'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);
      expect(find.text('ALL-IN'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('MISS DEAL'), findsOneWidget);
    });

    testWidgets('disabled buttons are not tappable', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.idle);

      var tappedAction = <CcAction>[];
      await tester.pumpWidget(_buildTestWidget(
        container: container,
        onAction: (action, {int? amount}) => tappedAction.add(action),
      ));
      await tester.pump();

      // FOLD should be disabled in IDLE state
      await tester.tap(find.text('FOLD'));
      await tester.pump();
      expect(tappedAction, isEmpty, reason: 'FOLD should be disabled in IDLE');

      // DEAL should be disabled in IDLE state
      await tester.tap(find.text('DEAL'));
      await tester.pump();
      expect(tappedAction, isEmpty, reason: 'DEAL should be disabled in IDLE');

      // NEW HAND should be enabled in IDLE state
      await tester.tap(find.text('NEW HAND'));
      await tester.pump();
      expect(tappedAction, [CcAction.newHand]);
    });

    testWidgets('dynamic label changes: CHECK vs CALL', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.preFlop);
      container.read(hasBetToMatchProvider.notifier).state = false;

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // No bet → CHECK
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);

      // Set bet to match
      container.read(hasBetToMatchProvider.notifier).state = true;
      await tester.pump();

      // With bet → CALL
      expect(find.text('CALL'), findsOneWidget);
      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('all 8 buttons render in PRE_FLOP state', (tester) async {
      final container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
      container.read(handFsmProvider.notifier).forceState(HandFsm.preFlop);

      await tester.pumpWidget(_buildTestWidget(container: container));
      await tester.pump();

      // All street-action buttons should be present
      expect(find.text('NEW HAND'), findsOneWidget);
      expect(find.text('DEAL'), findsOneWidget);
      expect(find.text('FOLD'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.text('BET'), findsOneWidget);
      expect(find.text('ALL-IN'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('MISS DEAL'), findsOneWidget);
    });
  });
}
