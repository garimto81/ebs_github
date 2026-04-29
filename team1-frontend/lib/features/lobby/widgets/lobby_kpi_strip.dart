// EBS Lobby — KPI strip (`.kpi-strip` from design source).
//
// A horizontal row of pad-24 KPI cards with right-divider, each carrying a
// small uppercase label, a large monospace value, and an optional caption.

import 'package:flutter/material.dart';

import '../../../foundation/theme/design_tokens.dart';
import '../../../foundation/theme/ebs_typography.dart';

/// Tone affects the value color only.
enum KpiTone { neutral, live, warn, danger }

class KpiCard {
  const KpiCard({
    required this.label,
    required this.value,
    this.sub,
    this.tone = KpiTone.neutral,
  });

  final String label;
  final String value;
  final String? sub;
  final KpiTone tone;
}

class LobbyKpiStrip extends StatelessWidget {
  const LobbyKpiStrip({super.key, required this.cards});
  final List<KpiCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.lightBg,
        border: Border(
          bottom: BorderSide(color: DesignTokens.lightLine),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < cards.length; i++) _KpiCell(
                card: cards[i],
                showRight: i < cards.length - 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({required this.card, required this.showRight});

  final KpiCard card;
  final bool showRight;

  @override
  Widget build(BuildContext context) {
    final color = switch (card.tone) {
      KpiTone.live => DesignTokens.liveInk,
      KpiTone.warn => DesignTokens.warnInk,
      KpiTone.danger => DesignTokens.dangerInk,
      KpiTone.neutral => DesignTokens.lightInk,
    };

    return Container(
      constraints: const BoxConstraints(minWidth: DesignChrome.kpiMinWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignChrome.kpiPadX,
        vertical: DesignChrome.kpiPadY,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: showRight
              ? const BorderSide(color: DesignTokens.lightLineSoft)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.label, style: EbsTypography.kpiLabel),
          const SizedBox(height: 4),
          Text(card.value, style: EbsTypography.kpiValue.copyWith(color: color)),
          if (card.sub != null) ...[
            const SizedBox(height: 2),
            Text(
              card.sub!,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamilyMono,
                fontSize: 11,
                color: DesignTokens.lightInk3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
