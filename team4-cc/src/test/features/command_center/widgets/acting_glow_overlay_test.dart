// ActingGlowOverlay smoke tests — Cycle 19 Wave 4 (U7).
//
// 검증 범위:
//   - active=false 시 child 가 untouched 로 렌더 (RepaintBoundary / shadow 없음).
//   - active=true 시 RepaintBoundary + AnimatedBuilder 가 보이고 pulse 가 tick.
//   - active toggle 시 ticker 가 stop / restart.
//   - dispose 시 ticker leak 없음.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/acting_glow_overlay.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('inactive: renders child untouched (no RepaintBoundary)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const ActingGlowOverlay(
          active: false,
          child: SizedBox(
            key: Key('inner'),
            width: 50,
            height: 50,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('inner')), findsOneWidget);

    final repaintBoundaries = find.descendant(
      of: find.byType(ActingGlowOverlay),
      matching: find.byType(RepaintBoundary),
    );
    expect(repaintBoundaries, findsNothing);
  });

  testWidgets('active: wraps child in RepaintBoundary + AnimatedBuilder',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const ActingGlowOverlay(
          active: true,
          duration: Duration(milliseconds: 100),
          child: SizedBox(
            key: Key('inner'),
            width: 50,
            height: 50,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('inner')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ActingGlowOverlay),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ActingGlowOverlay),
        matching: find.byType(AnimatedBuilder),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('toggle active=false -> true -> false starts/stops cleanly',
      (tester) async {
    Widget build(bool active) => wrap(
          ActingGlowOverlay(
            active: active,
            duration: const Duration(milliseconds: 80),
            child: const SizedBox(width: 40, height: 40),
          ),
        );

    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(build(false));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(ActingGlowOverlay),
        matching: find.byType(RepaintBoundary),
      ),
      findsNothing,
    );
  });
}
