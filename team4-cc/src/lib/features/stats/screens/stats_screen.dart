// BS-05-07 Statistics screen wrapper (CCR-027, AT-04).
// Delegates to At04StatisticsScreen for full implementation.

import 'package:flutter/material.dart';

import '../../command_center/screens/at_04_statistics_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) => const At04StatisticsScreen();
}
