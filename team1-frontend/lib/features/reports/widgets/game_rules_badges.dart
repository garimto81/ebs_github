import 'package:flutter/material.dart';

/// Game-rules badge row — Ante / Straddle / Run It Twice (Cycle 7, v03).
///
/// Reused in both the Reports → Hands Summary list (one badge per row,
/// compact) and the HandDetail header (full label + tooltip). Visibility
/// is value-driven: nothing renders when no v03 rule applies.
///
/// Badge color palette intentionally distinct so a glance reveals which
/// rule(s) shaped the hand:
///   - Ante      → indigo  (forced pre-hand contribution)
///   - Straddle  → orange  (voluntary blind raise)
///   - Run It Twice → teal (post-allin split-board agreement)
class GameRulesBadges extends StatelessWidget {
  final int anteAmount;
  final int? straddleAmount;
  final int runItTwiceCount;

  /// When true (table row context), badges are tighter and abbreviated.
  /// When false (detail header), badges include amount labels + tooltip.
  final bool compact;

  const GameRulesBadges({
    super.key,
    required this.anteAmount,
    required this.straddleAmount,
    required this.runItTwiceCount,
    this.compact = false,
  });

  String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (anteAmount > 0) {
      badges.add(_Badge(
        label: compact ? 'A' : 'Ante ${_fmt(anteAmount)}',
        color: Colors.indigo,
        tooltip: 'Ante — forced pre-hand contribution: ${_fmt(anteAmount)} per player',
        compact: compact,
      ));
    }

    if (straddleAmount != null && straddleAmount! > 0) {
      badges.add(_Badge(
        label: compact ? 'S' : 'Straddle ${_fmt(straddleAmount!)}',
        color: Colors.orange.shade800,
        tooltip: 'Straddle — voluntary blind raise posted: ${_fmt(straddleAmount!)}',
        compact: compact,
      ));
    }

    if (runItTwiceCount > 1) {
      badges.add(_Badge(
        label: compact ? 'RIT×$runItTwiceCount' : 'Run It Twice (×$runItTwiceCount)',
        color: Colors.teal.shade700,
        tooltip:
            'Run It $runItTwiceCount Times — board dealt $runItTwiceCount independent runs after all-in',
        compact: compact,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: 4,
      children: badges,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;
  final bool compact;

  const _Badge({
    required this.label,
    required this.color,
    required this.tooltip,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );

    return Tooltip(message: tooltip, child: chip);
  }
}
