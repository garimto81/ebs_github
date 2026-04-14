// Layer 1: Equity Bar (auto from Engine EquityUpdated).
//
// Displays win probability as percentage text only (no progress bar per UI-02).
// Monospace font, white text.

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_typography.dart';

/// Displays win probability as percentage text.
///
/// - [equity] 0.0 - 1.0: displayed as "45%"
/// - [equity] null: not calculated yet, renders nothing
class EquityBarLayer extends StatelessWidget {
  const EquityBarLayer({
    super.key,
    this.equity,
  });

  /// Win probability, 0.0 to 1.0. null = not calculated / not applicable.
  final double? equity;

  @override
  Widget build(BuildContext context) {
    if (equity == null) return const SizedBox.shrink();

    final pct = (equity! * 100).round();

    return Text(
      '$pct%',
      style: EbsTypography.equity.copyWith(color: Colors.white),
    );
  }
}
