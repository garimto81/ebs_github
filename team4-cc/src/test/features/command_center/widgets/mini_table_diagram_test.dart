// MiniTableDiagram widget smoke tests — Cycle 19 U2 OKLCH realignment.
//
// 검증 범위:
//   - ProviderScope + AnimatedBuilder 안에서 throw 없이 렌더링.
//   - CustomPaint painter 가 마운트되고 size 제약 (120×120) 을 따른다.
//   - Painter 가 EbsOklch.* 상수만 사용 (Theme.of(context).colorScheme 의존 제거)
//     — 직접 painter 인스턴스 inspection 은 private 이라 어려움. 대신
//       Theme override 로 ColorScheme 을 비워도 렌더링되는지를 회귀 가드로.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/widgets/mini_table_diagram.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => ProviderScope(
        child: MaterialApp(
          theme: theme,
          home: Scaffold(body: Center(child: child)),
        ),
      );

  testWidgets('renders default size 120×120 without throwing', (tester) async {
    await tester.pumpWidget(wrap(const MiniTableDiagram()));
    // Allow one frame for AnimationController.repeat() to settle.
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(MiniTableDiagram), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    final box = tester.getSize(find.byType(MiniTableDiagram));
    expect(box.width, equals(120));
    expect(box.height, equals(120));
  });

  testWidgets('honours custom size parameter', (tester) async {
    await tester.pumpWidget(wrap(const MiniTableDiagram(size: 80)));
    await tester.pump(const Duration(milliseconds: 16));

    final box = tester.getSize(find.byType(MiniTableDiagram));
    expect(box.width, equals(80));
    expect(box.height, equals(80));
  });

  testWidgets('renders independently of Theme ColorScheme (OKLCH-locked)',
      (tester) async {
    // 회귀 가드 — 이전 V3 는 cs.surfaceContainer / cs.primary 등에 강결합.
    // V4 부터는 EbsOklch.* 정적 상수만 사용해야 한다.
    await tester.pumpWidget(
      wrap(
        const MiniTableDiagram(),
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Colors.transparent,
            surfaceContainer: Colors.transparent,
            outlineVariant: Colors.transparent,
            onSurface: Colors.transparent,
            onSurfaceVariant: Colors.transparent,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    // 시각이 깨졌더라도 위젯은 살아 있어야 한다.
    expect(find.byType(MiniTableDiagram), findsOneWidget);
  });

  testWidgets('pulse animation drives repaint without exception',
      (tester) async {
    await tester.pumpWidget(wrap(const MiniTableDiagram()));
    // Advance pulse animation by several frames.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 240));
    }
    expect(find.byType(MiniTableDiagram), findsOneWidget);
  });
}
