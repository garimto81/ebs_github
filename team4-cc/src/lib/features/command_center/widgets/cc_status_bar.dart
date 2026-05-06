// CC Status Bar — V2 of B-team4-011 visual uplift.
//
// 디자인 reference: claude-design-archive/2026-05-06/cc-react-extracted/App.jsx
//   §"statusbar" (StatusBar 컴포넌트 — BO/RFID/Engine 통합 + 좌/중/우 3-zone).
//
// 통합 정책 (V2 + V10 결합):
//   좌측 그룹: BO/RFID/Engine dot 3종 + Operator + Table
//   중앙 그룹: Hand# + Phase + GameType/Blinds + Level + POT 강조 (V10)
//   우측 그룹: Players (active/total) + 아이콘 슬롯
//
// 본 위젯은 기존 _Toolbar + _InfoBar 와 **공존** 가능 (선택적 교체).
// 통합 결정은 다음 turn 사용자 검토 후. D7 / 통신 / HandFSM 변경 없음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/ws_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/config_provider.dart';
import '../providers/engine_connection_provider.dart';
import '../providers/hand_display_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

/// Integrated CC Status Bar (height 40px).
class CcStatusBar extends ConsumerWidget {
  const CcStatusBar({super.key});

  static const double _heightPx = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final handFsm = ref.watch(handFsmProvider);
    final wsState = ref.watch(wsConnectionStateProvider);
    final engineConn = ref.watch(engineConnectionProvider);
    final seats = ref.watch(seatsProvider);
    final handNum = ref.watch(handNumberProvider);
    final pot = ref.watch(potTotalProvider);
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    final activePlayers = seats
        .where((s) => s.isOccupied && s.activity != PlayerActivity.folded)
        .length;
    final totalOccupied = seats.where((s) => s.isOccupied).length;

    return Container(
      height: _heightPx,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          _LeftGroup(
            wsState: wsState,
            engineStage: engineConn.stage,
            operatorName: auth.role ?? '—',
            tableLabel: config.tableName.isEmpty
                ? 'Table #${config.tableNumber}'
                : config.tableName,
          ),
          const Spacer(),
          _CenterGroup(
            handNumber: handNum,
            phase: handFsm,
            gameType: config.gameType.name.toUpperCase(),
            blindsLabel: _blindsText(
              config.smallBlind,
              config.bigBlind,
              config.ante,
            ),
            potAmount: pot, // V10 — POT 강조
          ),
          const Spacer(),
          _RightGroup(
            activePlayers: activePlayers,
            totalPlayers: totalOccupied,
          ),
        ],
      ),
    );
  }

  static String _blindsText(int sb, int bb, int ante) {
    final base = '$sb/$bb';
    return ante > 0 ? '$base (ante $ante)' : base;
  }
}

// ---------------------------------------------------------------------------
// Left group — connection dots + Op + Table
// ---------------------------------------------------------------------------

class _LeftGroup extends StatelessWidget {
  const _LeftGroup({
    required this.wsState,
    required this.engineStage,
    required this.operatorName,
    required this.tableLabel,
  });

  final WsConnectionState wsState;
  final EngineConnectionStage engineStage;
  final String operatorName;
  final String tableLabel;

  @override
  Widget build(BuildContext context) {
    final boColor = _wsColor(wsState);
    final engineColor = _engineColor(engineStage);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusDot(label: 'BO', color: boColor, tooltip: wsState.name),
        const SizedBox(width: EbsSpacing.sm),
        const _StatusDot(
          label: 'RFID',
          color: Color(0xFF66BB6A), // Mock OK by default
          tooltip: 'RFID HAL — Mock active',
        ),
        const SizedBox(width: EbsSpacing.sm),
        _StatusDot(
          label: 'Engine',
          color: engineColor,
          tooltip: engineStage.name,
        ),
        const SizedBox(width: EbsSpacing.md),
        _KeyVal(label: 'Op', value: operatorName),
        const SizedBox(width: EbsSpacing.sm),
        _KeyVal(label: 'Table', value: tableLabel),
      ],
    );
  }

  Color _wsColor(WsConnectionState s) {
    return switch (s) {
      WsConnectionState.connected    => const Color(0xFF66BB6A),
      WsConnectionState.connecting   => const Color(0xFFFFA726),
      WsConnectionState.reconnecting => const Color(0xFFFFA726),
      WsConnectionState.failed       => const Color(0xFFEF5350),
      WsConnectionState.disconnected => const Color(0xFF9E9E9E),
    };
  }

  Color _engineColor(EngineConnectionStage s) {
    return switch (s) {
      EngineConnectionStage.online     => const Color(0xFF66BB6A),
      EngineConnectionStage.connecting => const Color(0xFFFFA726),
      EngineConnectionStage.degraded   => const Color(0xFFFFA726),
      EngineConnectionStage.offline    => const Color(0xFFEF5350),
    };
  }
}

// ---------------------------------------------------------------------------
// Center group — Hand# + Phase + GameType/Blinds + POT (V10)
// ---------------------------------------------------------------------------

class _CenterGroup extends StatelessWidget {
  const _CenterGroup({
    required this.handNumber,
    required this.phase,
    required this.gameType,
    required this.blindsLabel,
    required this.potAmount,
  });

  final int handNumber;
  final HandFsm phase;
  final String gameType;
  final String blindsLabel;
  final int potAmount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (phaseLabel, phaseColor) = _phaseLook(phase);
    final isLive = phase != HandFsm.idle && phase != HandFsm.handComplete;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hand #
        Text(
          'Hand #$handNumber',
          style: EbsTypography.toolbarTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(width: EbsSpacing.sm),
        // Phase pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.2),
            border: Border.all(color: phaseColor, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            phaseLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: phaseColor,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: EbsSpacing.sm),
        // GameType + Blinds
        _KeyVal(label: gameType, value: blindsLabel, mono: true),
        // POT (V10) — only when live
        if (isLive) ...[
          const SizedBox(width: EbsSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.18),
              border: Border.all(color: cs.primary, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'POT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${_fmt(potAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static (String, Color) _phaseLook(HandFsm fsm) => switch (fsm) {
        HandFsm.idle          => ('IDLE', const Color(0xFF9E9E9E)),
        HandFsm.setupHand     => ('SETUP', const Color(0xFFFFA726)),
        HandFsm.preFlop       => ('PRE-FLOP', const Color(0xFF42A5F5)),
        HandFsm.flop          => ('FLOP', const Color(0xFF66BB6A)),
        HandFsm.turn          => ('TURN', const Color(0xFFAB47BC)),
        HandFsm.river         => ('RIVER', const Color(0xFFEF5350)),
        HandFsm.showdown      => ('SHOWDOWN', const Color(0xFFFDD835)),
        HandFsm.handComplete  => ('COMPLETE', const Color(0xFF78909C)),
        HandFsm.runItMultiple => ('RUN IT', const Color(0xFFFF7043)),
      };
}

// ---------------------------------------------------------------------------
// Right group — Players ratio + icon slots
// ---------------------------------------------------------------------------

class _RightGroup extends StatelessWidget {
  const _RightGroup({
    required this.activePlayers,
    required this.totalPlayers,
  });

  final int activePlayers;
  final int totalPlayers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeyVal(
          label: 'Players',
          value: '$activePlayers/$totalPlayers',
          mono: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
    required this.color,
    required this.tooltip,
  });

  final String label;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label — $tooltip',
      waitDuration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: EbsTypography.infoBar.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: EbsTypography.shortcutHint.copyWith(
            fontSize: 10,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

String _fmt(int v) {
  if (v < 1000) return v.toString();
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
