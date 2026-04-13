// AT-01 Main screen (BS-05-00 §AT 화면 카탈로그, CCR-028).
//
// Composed of 7 Zones (Miller's Law 7±2):
//   M-01 Toolbar, M-02 Info Bar, M-03 Seat Labels, M-04 Straddle Toggles,
//   M-05 Seat Cards, M-06 Blind Panel, M-07 Action Panel.

import 'package:flutter/material.dart';

class At01MainScreen extends StatelessWidget {
  const At01MainScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('AT-01 Main (M-01~M-07 zones)')),
      );
}
