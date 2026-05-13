// CC Status Bar — V3 (Cycle 19 U2 OKLCH realignment).
//
// 디자인 reference:
//   - HTML SSOT: `docs/mockups/EBS Command Center/app.css` §".statusbar"
//   - Spec: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13
//
// V3 변경 — Broadcast Dark Amber OKLCH 정합:
//   * `cs.surfaceContainerHigh` → `EbsOklch.bg1`  (`.statusbar { background: var(--bg-1) }`)
//   * `cs.outlineVariant`       → `EbsOklch.line` (`border-bottom: 1px solid var(--line)`)
//   * `cs.primary` (POT 강조)   → `EbsOklch.accent` (`.phase.live { color: var(--accent) }`)
//   * Material 하드코딩 dot 색 → `EbsOklch.ok | warn | err | fg3` (`.dot.ok / .dot.warn / .dot.err`)
//   * Phase pill Material 색  → 의미 보존 후 OKLCH 매핑 (HTML SSOT 의 phase 시각 룰 정합)
//
// 통합 정책 (V2 + V10 결합):
//   좌측 그룹: BO/RFID/Engine dot 3종 + Operator + Table
//   중앙 그룹: Hand# + Phase + GameType/Blinds + Level + POT 강조 (V10)
//   우측 그룹: Players (active/total) + 아이콘 슬롯
//
// 본 위젯은 기존 _Toolbar + _InfoBar 와 **공존** 가능 (선택적 교체).
// D7 / 통신 / HandFSM 변경 없음.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/ws_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../foundation/theme/ebs_oklch.dart';
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

    final activePlayers = seats
        .where((s) => s.isOccupied && s.activity != PlayerActivity.folded)
        .length;
    final totalOccupied = seats.where((s) => s.isOccupied).length;

    return Container(
      height: _heightPx,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: const BoxDecoration(
        color: EbsOklch.bg1,
        border: Border(bottom: BorderSide(color: EbsOklch.line)),
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
            currentAnte: config.ante,
            onAnteTap: () => _showAnteOverrideDialog(context, ref, config.ante),
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

  /// v03 cycle 7 #330 — Manual ante override dialog.
  /// Operator can edit ante mid-hand. Tied to ConfigNotifier.setAnteOverride.
  static Future<void> _showAnteOverrideDialog(
    BuildContext context,
    WidgetRef ref,
    int currentAnte,
  ) async {
    final controller = TextEditingController(text: currentAnte.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ante Override'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manual ante (chips). 0 = no ante.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Ante amount',
                hintText: 'e.g., 25',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed >= 0) {
                  Navigator.of(ctx).pop(parsed);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed >= 0) {
                Navigator.of(ctx).pop(parsed);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref.read(configProvider.notifier).setAnteOverride(result);
    }
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
          color: EbsOklch.ok, // Mock HAL = OK by default
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

  // HTML SSOT — `.dot.ok | .dot.warn | .dot.err` 정합.
  Color _wsColor(WsConnectionState s) {
    return switch (s) {
      WsConnectionState.connected    => EbsOklch.ok,
      WsConnectionState.connecting   => EbsOklch.warn,
      WsConnectionState.reconnecting => EbsOklch.warn,
      WsConnectionState.failed       => EbsOklch.err,
      WsConnectionState.disconnected => EbsOklch.fg3,
    };
  }

  Color _engineColor(EngineConnectionStage s) {
    return switch (s) {
      EngineConnectionStage.online     => EbsOklch.ok,
      EngineConnectionStage.connecting => EbsOklch.warn,
      EngineConnectionStage.degraded   => EbsOklch.warn,
      EngineConnectionStage.offline    => EbsOklch.err,
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
    required this.currentAnte,
    required this.onAnteTap,
  });

  final int handNumber;
  final HandFsm phase;
  final String gameType;
  final String blindsLabel;
  final int potAmount;
  final int currentAnte;
  final VoidCallback onAnteTap;

  @override
  Widget build(BuildContext context) {
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
        // Phase pill — `.phase.live { color: var(--accent); background: var(--accent-soft) }`
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
        // GameType + Blinds — tap to open ante override dialog (v03 cycle 7 #330)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onAnteTap,
            child: Tooltip(
              message: 'Tap to override ante (current: $currentAnte)',
              child: Container(
                key: const ValueKey('cc-status-blinds-tap'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: currentAnte > 0
                      ? EbsOklch.accentSoft
                      : Colors.transparent,
                  border: Border.all(
                    color: currentAnte > 0
                        ? EbsOklch.accent
                        : EbsOklch.lineSoft,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child:
                    _KeyVal(label: gameType, value: blindsLabel, mono: true),
              ),
            ),
          ),
        ),
        // POT (V10) — only when live. `.md-pot` (accent border + accent-soft glow).
        if (isLive) ...[
          const SizedBox(width: EbsSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: EbsOklch.accentSoft,
              border: Border.all(color: EbsOklch.accent, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'POT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: EbsOklch.accent,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${_fmt(potAmount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: EbsOklch.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Phase pill 색 — HTML SSOT 의 phase 분류 시각 룰 정합.
  // LIVE 상태 (preFlop/flop/turn/river/showdown) 는 accent / accent-strong /
  // info / ok / pos-bb 등 의미 있는 OKLCH 토큰으로 매핑.
  static (String, Color) _phaseLook(HandFsm fsm) => switch (fsm) {
        HandFsm.idle          => ('IDLE', EbsOklch.fg3),
        HandFsm.setupHand     => ('SETUP', EbsOklch.warn),
        HandFsm.preFlop       => ('PRE-FLOP', EbsOklch.info),
        HandFsm.flop          => ('FLOP', EbsOklch.ok),
        HandFsm.turn          => ('TURN', EbsOklch.posBb),
        HandFsm.river         => ('RIVER', EbsOklch.err),
        HandFsm.showdown      => ('SHOWDOWN', EbsOklch.accent),
        HandFsm.handComplete  => ('COMPLETE', EbsOklch.fg2),
        HandFsm.runItMultiple => ('RUN IT', EbsOklch.accentStrong),
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
    // HTML SSOT — `.sb-item .lbl { color: var(--fg-2) }` + `.val { color: var(--fg-0) }`.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: EbsTypography.shortcutHint.copyWith(
            fontSize: 10,
            color: EbsOklch.fg2,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            color: EbsOklch.fg0,
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
