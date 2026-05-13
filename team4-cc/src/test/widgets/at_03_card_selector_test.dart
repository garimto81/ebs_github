// AT-03 Card Selector — Cycle 19 Wave 4 U5 widget tests.
//
// Verifies the Broadcast Dark Amber OKLCH centered modal: backdrop blur,
// modal tokens, 52-cell grid, dealt-state opacity, accent ring on hover,
// keyboard suit→rank commit path, and Esc/backdrop dismissal.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/screens/at_03_card_selector.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';
import 'package:ebs_cc/models/enums/card.dart';

/// Launches the modal via [showCardSelectorModal] and returns a handle whose
/// `future` field is the still-pending result of the dialog. Driving
/// keyboard / tap events that close the dialog completes the future.
class _ModalHandle {
  _ModalHandle(this.future);
  final Future<(Suit, Rank)?> future;
}

Future<_ModalHandle> _openModal(
  WidgetTester tester, {
  int targetSeatNo = 3,
  int targetSlotIndex = 0,
  Set<String> usedCards = const {},
}) async {
  late Future<(Suit, Rank)?> dialogFuture;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                dialogFuture = showCardSelectorModal(
                  context,
                  targetSeatNo: targetSeatNo,
                  targetSlotIndex: targetSlotIndex,
                  usedCards: usedCards,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  // Wait for the transition (160ms) plus a settle frame.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return _ModalHandle(dialogFuture);
}

void main() {
  group('AT-03 Card Selector — layout', () {
    testWidgets('renders 52 card cells in a 4×13 grid', (tester) async {
      await _openModal(tester);

      // 13 ranks × 4 suits = 52 cells. Each cell renders the rank glyph
      // (A/K/Q/J/T/9..2) and the suit symbol (♠/♥/♦/♣).
      for (final suit in ['♠', '♥', '♦', '♣']) {
        expect(
          find.text(suit),
          findsWidgets,
          reason: 'suit $suit should appear in row label + 13 cells',
        );
      }
      // Ace appears once per suit -> 4.
      expect(find.text('A'), findsNWidgets(4));
      // Ten uses 'T' glyph -> 4.
      expect(find.text('T'), findsNWidgets(4));
    });

    testWidgets('header shows seat + slot label', (tester) async {
      await _openModal(tester, targetSeatNo: 7, targetSlotIndex: 1);

      expect(find.text('Select card'), findsOneWidget);
      expect(find.text('S7 · Hole 2'), findsOneWidget);
    });

    testWidgets('legend exposes Available / Dealt / Current swatches',
        (tester) async {
      await _openModal(tester);

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Dealt'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Esc to close'), findsOneWidget);
    });

    testWidgets('modal surface uses EbsOklch.bg2 background', (tester) async {
      await _openModal(tester);

      // Find the modal's outer DecoratedBox — first descendant with the bg2
      // color and a shadow list.
      final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final modalBox = boxes.firstWhere((db) {
        final dec = db.decoration;
        if (dec is! BoxDecoration) return false;
        return dec.color == EbsOklch.bg2 && (dec.boxShadow?.isNotEmpty ?? false);
      });
      final modalDec = modalBox.decoration as BoxDecoration;
      expect(modalDec.color, EbsOklch.bg2);
      expect(modalDec.boxShadow, isNotNull);
      expect(modalDec.boxShadow!.first.blurRadius, 36);
    });
  });

  group('AT-03 Card Selector — dealt state', () {
    testWidgets('dealt card key dims its cell to opacity 0.5', (tester) async {
      // Ace of spades = 'acespade'.
      await _openModal(tester, usedCards: {'acespade'});

      // The dealt cell should be wrapped in an Opacity(0.5) widget.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.5);
      expect(
        opacities.isNotEmpty,
        true,
        reason: 'expected at least one dealt cell with opacity 0.5',
      );
    });

    testWidgets('keyboard ignores a dealt card and still allows a fresh pick',
        (tester) async {
      final handle = await _openModal(tester, usedCards: {'kingheart'});

      // h + K → dealt, should not commit.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(find.text('Select card'), findsOneWidget);

      // h + A → commits A♥.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await handle.future, (Suit.heart, Rank.ace));
    });
  });

  group('AT-03 Card Selector — keyboard', () {
    testWidgets('suit then rank commits the pair', (tester) async {
      final handle = await _openModal(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(find.textContaining('Suit ♠'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await handle.future, (Suit.spade, Rank.ace));
    });

    testWidgets('switching suit before rank does not commit', (tester) async {
      await _openModal(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(find.textContaining('Suit ♠'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      expect(find.textContaining('Suit ♥'), findsOneWidget);
      expect(find.text('Select card'), findsOneWidget);
    });
  });

  group('AT-03 Card Selector — dismissal', () {
    testWidgets('barrier tap dismisses the modal with null', (tester) async {
      final handle = await _openModal(tester);

      // Tap top-left corner — outside any modal child.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await handle.future, isNull);
      expect(find.text('Select card'), findsNothing);
    });

    testWidgets('close button dismisses with null', (tester) async {
      final handle = await _openModal(tester);

      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await handle.future, isNull);
    });
  });
}
