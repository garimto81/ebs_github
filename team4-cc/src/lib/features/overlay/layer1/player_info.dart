// Layer 1: Player Info (name, stack, country flag).
// Uses SeatColors SSOT — CC-Overlay visual consistency (CCR-034).

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/theme/seat_colors.dart';

/// Country code → flag emoji conversion.
/// e.g., "US" → "🇺🇸", "KR" → "🇰🇷"
String _countryFlag(String countryCode) {
  if (countryCode.length != 2) return '';
  final upper = countryCode.toUpperCase();
  // Regional indicator symbols: A=0x1F1E6, B=0x1F1E7, ...
  final first = 0x1F1E6 + upper.codeUnitAt(0) - 0x41;
  final second = 0x1F1E6 + upper.codeUnitAt(1) - 0x41;
  return String.fromCharCodes([first, second]);
}

/// Formats a stack amount with comma separators.
String _formatStack(int stack) {
  final str = stack.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// Displays player name, stack, and country flag for overlay.
///
/// Background uses [SeatColors.active] for active seats.
class PlayerInfoLayer extends StatelessWidget {
  const PlayerInfoLayer({
    super.key,
    required this.name,
    this.stack = 0,
    this.countryCode = '',
    this.isActive = true,
  });

  final String name;
  final int stack;
  final String countryCode;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final flag = _countryFlag(countryCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? SeatColors.active.withValues(alpha: 0.85)
            : SeatColors.vacant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Flag + Name
          Text(
            flag.isNotEmpty ? '$flag $name' : name,
            style: EbsTypography.playerName.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Stack amount (monospace, comma-formatted)
          Text(
            _formatStack(stack),
            style: EbsTypography.stackAmount.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
