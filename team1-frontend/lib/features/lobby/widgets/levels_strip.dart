// EBS Lobby — Levels strip (`.levels` from design source).
//
// Now / Next / After level cards plus countdown clock to next level. Used
// inside TablesScreen between the KPI strip and the toolbar.

import 'package:flutter/material.dart';

import '../../../foundation/theme/design_tokens.dart';
import '../../../foundation/theme/ebs_typography.dart';

class LobbyLevel {
  const LobbyLevel({
    required this.role,
    required this.blinds,
    required this.meta,
  });

  /// e.g. `Now · L17`, `Next · L18`, `L19`
  final String role;

  /// e.g. `6,000 / 12,000`
  final String blinds;

  /// e.g. `ante 12,000 · 60min`
  final String meta;
}

class LevelsStrip extends StatelessWidget {
  const LevelsStrip({
    super.key,
    required this.now,
    required this.next,
    this.after,
    this.countdownLabel = 'NEXT',
    this.countdown = '—',
  });

  final LobbyLevel now;
  final LobbyLevel next;
  final LobbyLevel? after;
  final String countdownLabel;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: DesignTokens.lightBg,
        border: Border(
          bottom: BorderSide(color: DesignTokens.lightLine),
        ),
      ),
      child: Row(
        children: [
          const _Caption(text: 'LEVELS'),
          const SizedBox(width: 12),
          _LevelCard(level: now, accent: DesignTokens.dangerBase, tinted: true),
          const SizedBox(width: 8),
          _LevelCard(level: next, accent: DesignTokens.liveBase),
          if (after != null) ...[
            const SizedBox(width: 8),
            _LevelCard(level: after!),
          ],
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                countdownLabel,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamilyUi,
                  fontSize: 10,
                  color: DesignTokens.lightInk4,
                  letterSpacing: 0.12 * 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(countdown, style: EbsTypography.levelClock),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamilyUi,
        fontSize: 10,
        color: DesignTokens.lightInk4,
        letterSpacing: 0.10 * 10,
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    this.accent,
    this.tinted = false,
  });

  final LobbyLevel level;
  final Color? accent;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final borderColor = accent ?? DesignTokens.lightLine;
    final bg = tinted
        ? DesignTokens.dangerBg.withValues(alpha: 0.4)
        : DesignTokens.lightBg;
    final roleColor = accent != null ? _darken(accent!) : DesignTokens.lightInk4;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.role.toUpperCase(),
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10 * 9,
              color: roleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.blinds,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DesignTokens.lightInk,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            level.meta,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              fontSize: 10,
              color: DesignTokens.lightInk3,
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color c) {
    // Approximate by interpolating toward black 40%.
    return Color.lerp(c, DesignTokens.lightInk, 0.35) ?? c;
  }
}
