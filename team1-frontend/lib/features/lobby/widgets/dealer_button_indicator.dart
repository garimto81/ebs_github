// Cycle 6 (#312) — Dealer button indicator.
//
// Visual "D" badge for the dealer seat. Standalone widget so it can be
// reused by:
//   • HandDemoOverlay (Cycle 6 evidence — top HUD)
//   • SeatDotCell (Tables grid — dealer seat in table row)
//   • TableDetailScreen (seat map cell — dealer marker on seat card)
//
// Composition reference: WSOP LIVE button = white disc with bold "D"
// border. We approximate with a flat circular badge so it works on any
// background (light or dark theme).

import 'package:flutter/material.dart';

class DealerButtonIndicator extends StatelessWidget {
  const DealerButtonIndicator({super.key, this.size = _defaultSize});

  /// Compact 14×14 button for tight grid rows.
  const DealerButtonIndicator.small({super.key}) : size = 14;

  /// Standard 22×22 button for seat map cells.
  const DealerButtonIndicator.standard({super.key}) : size = 22;

  /// Large 28×28 button for table detail seat cards.
  const DealerButtonIndicator.large({super.key}) : size = 28;

  final double size;

  static const double _defaultSize = 18;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Dealer button',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.85),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.55,
            height: 1,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
