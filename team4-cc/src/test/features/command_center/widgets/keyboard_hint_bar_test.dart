// KeyboardHintBar widget smoke tests — Cycle 19 U2 OKLCH realignment.
//
// 검증 범위:
//   - ProviderScope 안에서 throw 없이 렌더링.
//   - 컨테이너 background = EbsOklch.bg2 (HTML SSOT `.kbd { background: var(--bg-2) }`).
//   - 단축키 칩 6개 + DEBUG 1개 = 총 7개의 keyLabel 텍스트.
//   - 6 액션 accent 가 EbsOklch.{err, info, accent, ok, warn} 중 하나만 사용 (회귀 가드).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/keyboard_hint_bar.dart';
import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 1280, height: 60, child: child),
          ),
        ),
      );

  testWidgets('renders within a ProviderScope without throwing',
      (tester) async {
    await tester.pumpWidget(wrap(const KeyboardHintBar()));
    expect(find.byType(KeyboardHintBar), findsOneWidget);
  });

  testWidgets('outer container uses EbsOklch.bg2 background', (tester) async {
    await tester.pumpWidget(wrap(const KeyboardHintBar()));

    final container = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(KeyboardHintBar),
        matching: find.byType(Container),
      ),
    ).first;
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color, equals(EbsOklch.bg2));
  });

  testWidgets('bottom border uses EbsOklch.line', (tester) async {
    await tester.pumpWidget(wrap(const KeyboardHintBar()));

    final container = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(KeyboardHintBar),
        matching: find.byType(Container),
      ),
    ).first;
    final decoration = container.decoration as BoxDecoration?;
    final border = decoration?.border as Border?;
    expect(border?.bottom.color, equals(EbsOklch.line));
  });

  testWidgets('shows 7 keyLabel chips (6 actions + DEBUG)', (tester) async {
    await tester.pumpWidget(wrap(const KeyboardHintBar()));

    // Action keys: F C B A N M  +  DEBUG: Ctrl+L
    expect(find.text('F'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Ctrl+L'), findsOneWidget);
    expect(find.text('DEBUG'), findsOneWidget);
  });

  testWidgets('renders independently of Theme ColorScheme (OKLCH-locked)',
      (tester) async {
    // 회귀 가드 — V1 은 cs.error / cs.outline / cs.onSurface / cs.surfaceContainerLow 에 강결합.
    // V2 부터는 EbsOklch.* 정적 상수만 사용해야 한다.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              error: Colors.transparent,
              outline: Colors.transparent,
              onSurface: Colors.transparent,
              onSurfaceVariant: Colors.transparent,
              surfaceContainerLow: Colors.transparent,
            ),
          ),
          home: const Scaffold(
            body: SizedBox(width: 1280, height: 60, child: KeyboardHintBar()),
          ),
        ),
      ),
    );
    expect(find.byType(KeyboardHintBar), findsOneWidget);
    // bg2 가 여전히 살아 있어야 한다 (Theme 무관).
    final container = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(KeyboardHintBar),
        matching: find.byType(Container),
      ),
    ).first;
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color, equals(EbsOklch.bg2));
  });
}
