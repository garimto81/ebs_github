// Layer 1: Player Position marker (Dealer/SB/BB/UTG).
// Semi-automatic: CC SeatAssign or Engine StartHand trigger.
//
// Colored circle: Dealer=red, SB=yellow, BB=blue, others=white.

import 'package:flutter/material.dart';

import '../../../foundation/theme/seat_colors.dart';

/// Maps position string to color from SeatColors SSOT.
Color _positionColor(String? position) {
  if (position == null) return Colors.transparent;
  switch (position.toUpperCase()) {
    case 'BTN':
    case 'D':
      return SeatColors.dealer;
    case 'SB':
      return SeatColors.sb;
    case 'BB':
      return SeatColors.bb;
    case 'UTG':
      return SeatColors.utg;
    default:
      return SeatColors.positionDefault;
  }
}

/// Text color for contrast on position circle.
Color _positionTextColor(String? position) {
  if (position == null) return Colors.black;
  switch (position.toUpperCase()) {
    case 'SB': // Yellow background needs dark text
      return Colors.black87;
    default:
      return Colors.white;
  }
}

/// Renders a position marker circle with label.
///
/// - [position] null: hidden
/// - "BTN"/"D": red dealer button
/// - "SB": yellow small blind
/// - "BB": blue big blind
/// - "UTG" etc.: default white
class PlayerPositionLayer extends StatelessWidget {
  const PlayerPositionLayer({
    super.key,
    this.position,
    this.size = 28,
  });

  /// Position label: "BTN", "SB", "BB", "UTG", "MP", "CO", "HJ", etc.
  final String? position;

  /// Circle diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (position == null || position!.isEmpty) return const SizedBox.shrink();

    final bgColor = _positionColor(position);
    final textColor = _positionTextColor(position);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        position!.length > 3 ? position!.substring(0, 3) : position!,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
