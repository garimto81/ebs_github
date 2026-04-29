// EBS Lobby — 22x22 seat cell (`.seat.s-a/.s-e/.s-r/.s-w/.s-d` in styles.css).
//
// Used inside the Tables grid to render each of the 9 seats per table row.
// State enum mirrors the design source: active / empty / eliminated /
// waiting / dealer.

import 'package:flutter/material.dart';

import '../../../foundation/theme/design_tokens.dart';

enum SeatCellState { active, empty, eliminated, waiting, dealer }

class SeatDotCell extends StatelessWidget {
  const SeatDotCell({
    super.key,
    required this.state,
    required this.seatNo,
  });

  final SeatCellState state;

  /// 1..9 — displayed for non-empty seats.
  final int seatNo;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(state);
    final showLabel = state != SeatCellState.empty;
    final decoration = state == SeatCellState.empty
        ? BoxDecoration(
            color: spec.bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: DesignTokens.lightLineStrong,
              style: BorderStyle.solid,
              width: 1,
            ),
          )
        : BoxDecoration(
            color: spec.bg,
            borderRadius: BorderRadius.circular(3),
          );

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: decoration,
      alignment: Alignment.center,
      child: showLabel
          ? Text(
              '$seatNo',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamilyMono,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: spec.fg,
                decoration: state == SeatCellState.eliminated
                    ? TextDecoration.lineThrough
                    : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          : null,
    );
  }

  _SeatSpec _spec(SeatCellState s) {
    switch (s) {
      case SeatCellState.active:
        return const _SeatSpec(DesignTokens.liveBg, DesignTokens.liveInk);
      case SeatCellState.empty:
        return const _SeatSpec(
            DesignTokens.lightBgSunken, DesignTokens.lightInk5);
      case SeatCellState.eliminated:
        return const _SeatSpec(DesignTokens.dangerBg, DesignTokens.dangerInk);
      case SeatCellState.waiting:
        return const _SeatSpec(DesignTokens.warnBg, DesignTokens.warnInk);
      case SeatCellState.dealer:
        return const _SeatSpec(
            DesignTokens.lightBgSunken, DesignTokens.lightInk3);
    }
  }
}

class _SeatSpec {
  const _SeatSpec(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

/// Compact legend row (used at top of Tables screen toolbar right side).
class SeatLegendRow extends StatelessWidget {
  const SeatLegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(state: SeatCellState.active, label: 'Active'),
        SizedBox(width: 12),
        _LegendItem(state: SeatCellState.empty, label: 'Empty'),
        SizedBox(width: 12),
        _LegendItem(state: SeatCellState.eliminated, label: 'Elim'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.state, required this.label});
  final SeatCellState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: SeatDotCell(state: state, seatNo: 0),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyMono,
            fontSize: 10.5,
            color: DesignTokens.lightInk3,
          ),
        ),
      ],
    );
  }
}
