// Layer 1: Pot Display (auto from Engine bet accumulation).
//
// Center-positioned: "POT: $5,000" main pot with optional side pots below.
// Animated rolling counter on value change via TweenAnimationBuilder.

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_typography.dart';

/// Formats an integer amount with comma separators.
/// e.g., 5000 → "$5,000"
String _formatAmount(int amount) {
  if (amount < 0) return '\$0';
  final str = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return '\$$buffer';
}

/// Displays main pot and side pots for the current hand.
///
/// - [mainPot]: total main pot amount (0 = hidden)
/// - [sidePots]: list of side pot amounts (empty = no side pots)
class PotDisplayLayer extends StatelessWidget {
  const PotDisplayLayer({
    super.key,
    this.mainPot = 0,
    this.sidePots = const [],
  });

  final int mainPot;
  final List<int> sidePots;

  @override
  Widget build(BuildContext context) {
    if (mainPot <= 0 && sidePots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main pot with animated counter.
        if (mainPot > 0)
          _AnimatedPotLabel(
            label: 'POT',
            amount: mainPot,
            style: EbsTypography.potAmount.copyWith(color: Colors.white),
          ),
        // Side pots.
        for (int i = 0; i < sidePots.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _AnimatedPotLabel(
              label: 'Side ${i + 1}',
              amount: sidePots[i],
              style: EbsTypography.stackAmount.copyWith(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated label that rolls between old and new amounts.
class _AnimatedPotLabel extends StatelessWidget {
  const _AnimatedPotLabel({
    required this.label,
    required this.amount,
    required this.style,
  });

  final String label;
  final int amount;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: amount, end: amount),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Text(
          '$label: ${_formatAmount(value)}',
          style: style,
        );
      },
    );
  }
}
