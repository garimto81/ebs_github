// HoleCardSlot — 5-state widget contract (Manual_Card_Input.md §6.2).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/hole_card_slot.dart';

Future<void> _pumpSlot(
  WidgetTester tester,
  HoleCardSlotState state, {
  String? cardLabel,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: HoleCardSlot(
            state: state,
            cardLabel: cardLabel,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('EMPTY shows dash placeholder', (tester) async {
    await _pumpSlot(tester, HoleCardSlotState.empty);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('DETECTING shows contactless icon', (tester) async {
    await _pumpSlot(tester, HoleCardSlotState.detecting);
    expect(find.byIcon(Icons.contactless), findsOneWidget);
    // Keep the test deterministic: stop after one frame to avoid the
    // pulse animation looping the test runner forever.
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('DEALT renders provided card label', (tester) async {
    await _pumpSlot(tester, HoleCardSlotState.dealt, cardLabel: 'A♠');
    expect(find.text('A♠'), findsOneWidget);
  });

  testWidgets('FALLBACK shows TAP TO ENTER hint', (tester) async {
    await _pumpSlot(tester, HoleCardSlotState.fallback);
    expect(find.textContaining('TAP TO'), findsOneWidget);
  });

  testWidgets('WRONG_CARD shows error icon', (tester) async {
    await _pumpSlot(tester, HoleCardSlotState.wrongCard);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('tap forwards to onTap callback', (tester) async {
    var taps = 0;
    await _pumpSlot(
      tester,
      HoleCardSlotState.fallback,
      onTap: () => taps++,
    );
    await tester.tap(find.byType(HoleCardSlot));
    await tester.pump();
    expect(taps, 1);
  });
}
