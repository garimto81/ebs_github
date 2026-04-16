import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebs_lobby/app.dart';

void main() {
  testWidgets('EbsLobbyApp renders without error', (WidgetTester tester) async {
    // Set a desktop-size surface to avoid NavigationRail overflow
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: EbsLobbyApp()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EbsLobbyApp), findsOneWidget);
  });
}
