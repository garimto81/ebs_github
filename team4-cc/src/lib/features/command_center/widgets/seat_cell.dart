// M-05 Seat Cell widget (BS-05-03 §시각 규격, CCR-032).
// Uses SeatColors SSOT from foundation/theme for CC-Overlay consistency.
//
// UI-02 변경 (2026-04-13):
// - 국기 추가 (country_code → Flag emoji/icon)
// - Equity: '%' 숫자만 (프로그레스 바 제거)
// - 인라인 편집: 각 요소 탭 → 수정 다이얼로그 (화면 2 좌석 상세 패널 대체)
// - 수동 편집 우선 원칙: 동기화 아이콘(🔄)으로 DB 값 수용/거부 제어
// - 좌석 번호: S1~S10 (기존 S0~S9에서 변경)
//
// Cycle 19 Wave 3 (U3) — OKLCH token 정합.
// - Colors.white* / Color(0xFFFFD700) / Colors.red.shade* / amberAccent 등
//   잔존 하드코딩을 EbsOklch / EbsShadows / CardColors 토큰으로 치환.
// - ACTING glow: SeatColors.actionGlowTo 단일 BoxShadow → EbsShadows.glowAction
//   (accent ring + soft outer glow) 2-stop.
// - LAST 행 inline 구현 → ActionBadge 위젯으로 분리.
//
// Cycle 19 Wave 4 (U7) — ACTING glow extracted to `ActingGlowOverlay`.
//   인라인 `AnimationController + AnimatedBuilder` 로직을 재사용 가능한
//   `ActingGlowOverlay` 위젯으로 이관. SeatCell 은 ACTING-on 여부만 전달.
//   ticker / dispose 책임도 overlay 위젯이 소유 → 코드 단순화 + 시각 표현
//   재사용성 확보. 기타 layout / inline edit / context menu 동작 그대로.
//
// Cycle 20 Wave 3a (#437) — WSOP LIVE chip_count_synced glow.
//   `seat.lastChipUpdate` 가 새 timestamp 로 바뀔 때 (브레이크 webhook 수신)
//   `EbsShadows.glowAction` 을 1 초간 적용해 운영자에게 권위 동기화 신호를
//   시각화한다. ACTING glow 와 별개 (1 회성 tint).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/card_colors.dart';
import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_shadows.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/theme/seat_colors.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/config_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';
import 'acting_glow_overlay.dart';
import 'action_badge.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Convert ISO 3166-1 alpha-2 country code to flag emoji.
/// E.g. "US" → "🇺🇸", "KR" → "🇰🇷".
String _countryFlag(String code) {
  if (code.length != 2) return '';
  final upper = code.toUpperCase();
  final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCodes([first, second]);
}

/// Format integer stack with comma separators.
/// E.g. 10000 → "10,000".
String _formatStack(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// Note: `_suitDisplay` helper 제거 (2026-04-26 IMPL-007 D7).
// hole card 값을 표시하지 않으므로 suit symbol/color 매핑 불필요.

/// Position label for a seat (e.g. "BTN", "SB", "BB").
String? _positionLabel(SeatState seat) {
  if (seat.isDealer) return 'BTN';
  if (seat.isSB) return 'SB';
  if (seat.isBB) return 'BB';
  return null;
}

Color _positionColor(String label) {
  return switch (label) {
    'BTN' => SeatColors.dealer,
    'SB' => SeatColors.sb,
    'BB' => SeatColors.bb,
    _ => SeatColors.positionDefault,
  };
}

// ---------------------------------------------------------------------------
// SeatCell
// ---------------------------------------------------------------------------

class SeatCell extends ConsumerStatefulWidget {
  const SeatCell({required this.seatIndex, super.key});

  /// 1-based seat number (1..10).
  final int seatIndex;

  @override
  ConsumerState<SeatCell> createState() => _SeatCellState();
}

class _SeatCellState extends ConsumerState<SeatCell> {
  // U7 (cycle 19 Wave 4) — AnimationController / Tween ownership moved into
  // `ActingGlowOverlay`. SeatCell now passes the ACTING flag and lets the
  // overlay widget manage its ticker + dispose.

  // Cycle 20 #437 — chip_count_synced glow tint state.
  DateTime? _lastSeenChipUpdate;
  bool _chipSyncGlow = false;
  Timer? _chipSyncGlowTimer;

  @override
  void dispose() {
    _chipSyncGlowTimer?.cancel();
    super.dispose();
  }

  /// Called from `ref.listen` in build — if the seat's lastChipUpdate moved
  /// forward, light up the glow for 1 second.
  void _onSeatsChanged(
    List<SeatState>? prev,
    List<SeatState> next,
  ) {
    final nextSeat = next.firstWhere(
      (s) => s.seatNo == widget.seatIndex,
      orElse: () => next.first,
    );
    final ts = nextSeat.lastChipUpdate;
    if (ts == null) return;
    if (_lastSeenChipUpdate == ts) return;
    _lastSeenChipUpdate = ts;
    _chipSyncGlowTimer?.cancel();
    setState(() => _chipSyncGlow = true);
    _chipSyncGlowTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _chipSyncGlow = false);
    });
  }

  // -- seat state -----------------------------------------------------------

  SeatState _seatState(List<SeatState> seats) {
    return seats.firstWhere((s) => s.seatNo == widget.seatIndex);
  }

  // -- appearance -----------------------------------------------------------

  Color _backgroundColor(SeatState seat) {
    if (seat.isEmpty) return Colors.transparent;

    return switch (seat.activity) {
      PlayerActivity.folded => SeatColors.vacant,
      PlayerActivity.allIn => SeatColors.allIn,
      PlayerActivity.sittingOut => SeatColors.vacant,
      PlayerActivity.active => SeatColors.active,
    };
  }

  double _opacity(SeatState seat) {
    if (seat.isEmpty) return 1.0;
    return switch (seat.activity) {
      PlayerActivity.folded => SeatColors.foldedOpacity,
      PlayerActivity.sittingOut => SeatColors.sittingOutOpacity,
      _ => 1.0,
    };
  }

  BorderSide _borderSide(SeatState seat) {
    if (seat.isEmpty) {
      return const BorderSide(
        color: EbsOklch.line,
        width: 1.0,
        // Dashed border simulated via CustomPaint below for empty seats.
      );
    }
    if (seat.activity == PlayerActivity.allIn) {
      // ALL-IN gold ring → broadcast warn token (replaces 0xFFD700).
      return const BorderSide(color: EbsOklch.warn, width: 2.0);
    }
    return const BorderSide(color: EbsOklch.line, width: 1.0);
  }

  // -- inline edit helpers --------------------------------------------------

  void _editName(SeatState seat) {
    if (seat.player == null) return;
    final controller = TextEditingController(text: seat.player!.name);
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Player name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) {
      if (value != null && value.isNotEmpty) {
        final seats = ref.read(seatsProvider);
        final s = _seatState(seats);
        if (s.player != null) {
          // Update via notifier — modify player name.
          final notifier = ref.read(seatsProvider.notifier);
          notifier.vacateSeat(widget.seatIndex);
          notifier.seatPlayer(
            widget.seatIndex,
            s.player!.copyWith(name: value),
          );
        }
      }
    });
  }

  void _editStack(SeatState seat) {
    if (seat.player == null) return;
    final controller =
        TextEditingController(text: seat.player!.stack.toString());
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Stack'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'Stack amount'),
          onSubmitted: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) Navigator.of(ctx).pop(parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null) Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) {
      if (value != null) {
        ref.read(seatsProvider.notifier).updateStack(widget.seatIndex, value);
      }
    });
  }

  void _addPlayer() {
    final nameCtrl = TextEditingController();
    final stackCtrl = TextEditingController(text: '10000');
    final countryCtrl = TextEditingController(text: 'US');
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stackCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Stack'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: countryCtrl,
              maxLength: 2,
              decoration:
                  const InputDecoration(labelText: 'Country (2-letter)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true && nameCtrl.text.isNotEmpty) {
        final player = PlayerInfo(
          id: DateTime.now().millisecondsSinceEpoch, // temp id
          name: nameCtrl.text,
          stack: int.tryParse(stackCtrl.text) ?? 10000,
          countryCode: countryCtrl.text.toUpperCase(),
        );
        ref.read(seatsProvider.notifier).seatPlayer(widget.seatIndex, player);
      }
    });
  }

  // -- context menu ---------------------------------------------------------

  void _showContextMenu(SeatState seat) {
    if (seat.player == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Player'),
              onTap: () {
                Navigator.of(ctx).pop();
                _editName(seat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move Seat'),
              subtitle: const Text('Drag mode (placeholder)'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            ListTile(
              leading: Icon(
                seat.activity == PlayerActivity.sittingOut
                    ? Icons.event_seat
                    : Icons.event_seat_outlined,
              ),
              title: Text(
                seat.activity == PlayerActivity.sittingOut
                    ? 'Sit In'
                    : 'Sit Out',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(seatsProvider.notifier)
                    .toggleSitOut(widget.seatIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: EbsOklch.err),
              title: const Text('Vacate Seat'),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmVacate();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── 2026-05-07 B-team4-013: HTML 시안 패턴 5 다이얼로그 ──

  /// POS 행 onTap — None / D / SB / BB 토글.
  /// SeatNotifier.setDealer/setSB/setBB 가 단일 source 이므로 다른 좌석의 같은
  /// position 마커는 자동 해제됨.
  void _editPos(SeatState seat) {
    final notifier = ref.read(seatsProvider.notifier);
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('S${seat.seatNo} Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in const ['None', 'D (BTN)', 'SB', 'BB'])
              ListTile(
                dense: true,
                title: Text(p),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((sel) {
      if (sel == null) return;
      final s = widget.seatIndex;
      if (sel == 'None') {
        // Position 해제 — 모든 마커 false (다른 좌석이 다음에 setDealer 시 자동 이동)
        if (seat.isDealer) notifier.setDealer(-1);
        if (seat.isSB) notifier.setSB(-1);
        if (seat.isBB) notifier.setBB(-1);
      } else if (sel == 'D (BTN)') {
        notifier.setDealer(s);
      } else if (sel == 'SB') {
        notifier.setSB(s);
      } else if (sel == 'BB') {
        notifier.setBB(s);
      }
    });
  }

  /// CTRY 행 onTap — 2-letter ISO country code 입력.
  void _editFlag(SeatState seat) {
    if (seat.player == null) return;
    final ctrl = TextEditingController(text: seat.player!.countryCode);
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Country Code'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 2,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'ISO 3166-1 alpha-2 (e.g., KR, US)',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.toUpperCase()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(ctrl.text.trim().toUpperCase()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) {
      if (value == null || value.length != 2) return;
      final notifier = ref.read(seatsProvider.notifier);
      final p = seat.player!;
      // updateStack 패턴 — vacateSeat + seatPlayer 우회 위해 inline state replace.
      // 향후 SeatNotifier.updateCountry 추가 권장 (별도 PR).
      notifier.vacateSeat(widget.seatIndex);
      notifier.seatPlayer(
        widget.seatIndex,
        p.copyWith(countryCode: value),
      );
    });
  }

  /// BET 행 onTap — currentBet 직접 편집 (dev/manual override).
  /// Engine 응답이 SSOT 이지만 운영자 수동 보정 path 보존 (Player_Edit_Modal §4 정합).
  void _editBet(SeatState seat) {
    if (seat.player == null) return;
    final ctrl = TextEditingController(text: seat.currentBet.toString());
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('S${seat.seatNo} Bet (manual override)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'Current bet amount'),
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 0) Navigator.of(ctx).pop(n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text);
              if (n != null && n >= 0) Navigator.of(ctx).pop(n);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) {
      if (value == null) return;
      ref.read(seatsProvider.notifier).setCurrentBet(widget.seatIndex, value);
    });
  }

  /// LAST 행 onTap — activity enum 토글.
  void _editLastAction(SeatState seat) {
    showDialog<PlayerActivity>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('S${seat.seatNo} Last Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              ('Active (—)', PlayerActivity.active),
              ('FOLD', PlayerActivity.folded),
              ('ALL-IN', PlayerActivity.allIn),
              ('SIT OUT', PlayerActivity.sittingOut),
            ])
              ListTile(
                dense: true,
                title: Text(entry.$1),
                selected: seat.activity == entry.$2,
                onTap: () => Navigator.of(ctx).pop(entry.$2),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((value) {
      if (value == null) return;
      ref.read(seatsProvider.notifier).setActivity(widget.seatIndex, value);
    });
  }

  void _confirmVacate() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vacate Seat'),
        content: Text(
          'Remove player from seat S${widget.seatIndex}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vacate', style: TextStyle(color: EbsOklch.err)),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        ref.read(seatsProvider.notifier).vacateSeat(widget.seatIndex);
      }
    });
  }

  // -- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Cycle 20 #437 — listen for chip_count_synced bumps. Fires 1 s glow tint
    // when seat.lastChipUpdate advances. ref.listen is the Riverpod-sanctioned
    // way to react to state transitions from inside build.
    ref.listen<List<SeatState>>(seatsProvider, _onSeatsChanged);

    final seats = ref.watch(seatsProvider);
    final seat = _seatState(seats);

    final bgColor = _backgroundColor(seat);
    final opacity = _opacity(seat);
    final border = _borderSide(seat);

    Widget content;
    if (seat.isEmpty) {
      content = _buildEmptySeat();
    } else {
      content = _buildOccupiedSeat(seat);
    }

    // U7 — static surface (no animated BoxShadow). ACTING glow is layered on
    // top by `ActingGlowOverlay` below, which owns its own AnimationController.
    // Cycle 20 #437 — chip sync glow overrides the default card shadow for 1 s
    // when `_chipSyncGlow` is true. ACTING glow (actionOn) still wins via the
    // ActingGlowOverlay layered on top.
    final List<BoxShadow>? shadow = _chipSyncGlow
        ? EbsShadows.glowAction
        : (seat.actionOn ? null : EbsShadows.card);
    final Widget surface = Container(
      decoration: BoxDecoration(
        color: bgColor,
        border:
            seat.isEmpty ? _dashedBorder() : Border.fromBorderSide(border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: shadow,
      ),
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EbsSpacing.xs,
            vertical: EbsSpacing.xs,
          ),
          child: content,
        ),
      ),
    );

    final Widget cell = ActingGlowOverlay(
      active: seat.actionOn,
      borderRadius: BorderRadius.circular(6),
      child: surface,
    );

    // Tap → add player (empty) or inline edit name (occupied).
    // Long press → context menu (occupied only).
    return GestureDetector(
      onTap: seat.isEmpty ? _addPlayer : () => _editName(seat),
      onLongPress: seat.isEmpty ? null : () => _showContextMenu(seat),
      child: cell,
    );
  }

  // -- empty seat -----------------------------------------------------------

  Widget _buildEmptySeat() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: EbsOklch.bg2.withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: const Text('EMPTY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: EbsOklch.fg2, letterSpacing: 1.2)),
        ),
        const Spacer(),
        Center(child: Text('S${widget.seatIndex}',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
            color: EbsOklch.fg3))),
        const SizedBox(height: 8),
        const Center(child: Text('+ ADD PLAYER',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: EbsOklch.fg2, letterSpacing: 0.6))),
        const SizedBox(height: 4),
        const Center(child: Text('click to seat',
          style: TextStyle(fontSize: 10, color: EbsOklch.fg3))),
        const Spacer(),
      ],
    );
  }

  BoxBorder _dashedBorder() {
    // Flutter does not natively support dashed borders. Use a solid border
    // with reduced opacity as an approximation. A full dashed border would
    // require CustomPaint, which is deferred to a polish pass.
    return Border.all(color: EbsOklch.line, width: 1.0);
  }

  // -- occupied seat --------------------------------------------------------

  Widget _buildOccupiedSeat(SeatState seat) {
    final player = seat.player!;
    final flag = _countryFlag(player.countryCode);
    final posLabel = _positionLabel(seat);
    final handFsm = ref.watch(handFsmProvider);
    final preHand = handFsm == HandFsm.idle ||
        handFsm == HandFsm.showdown ||
        handFsm == HandFsm.handComplete;
    // v03: straddle marker (cycle 7 #330)
    final straddleSeats = ref.watch(configProvider).straddleSeats;
    final isStraddle = straddleSeats.contains(seat.seatNo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActingStrip(seat: seat, preHand: preHand, onDelete: _confirmVacate),
        const SizedBox(height: 3),
        // SEAT 행 — click to vacate (시안 PlayerColumn:50)
        _RowCell(
          label: null, value: 'S${seat.seatNo}', big: true,
          onTap: _confirmVacate,
        ),
        // POS 행 — None / D / SB / BB 토글
        _RowCell(
          label: 'POS', value: posLabel ?? '-',
          dim: posLabel == null,
          highlightColor: posLabel != null ? _positionColor(posLabel) : null,
          onTap: () => _editPos(seat),
        ),
        // CTRY 행 — 2-letter country code 편집
        _RowCell(
          label: 'CTRY', value: flag.isNotEmpty ? flag : 'XX',
          onTap: () => _editFlag(seat),
        ),
        // NAME 행 — 이름 편집
        _RowCell(label: 'NAME', value: player.name, onTap: () => _editName(seat)),
        // CARDS 행 — D7 가드 (onTap 추가 금지)
        if (seat.holeCards.isNotEmpty)
          _buildHoleCardBack(seat.holeCards.length)
        else
          const _RowCell(label: 'CARDS', value: '-', dim: true),
        // STACK 행 — stack 편집
        _RowCell(label: 'STACK',
          value: '\$${_formatStack(player.stack)}',
          mono: true, onTap: () => _editStack(seat)),
        // BET 행 — currentBet manual override
        _RowCell(label: 'BET',
          value: seat.currentBet > 0 ? '\$${_formatStack(seat.currentBet)}' : '-',
          mono: true, dim: seat.currentBet == 0,
          highlightColor: seat.currentBet > 0 ? EbsOklch.accent : null,
          onTap: () => _editBet(seat),
        ),
        // LAST 행 — activity enum 토글 (Cycle 19 U3: ActionBadge 위젯 이관)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: ActionBadge.fromActivity(
            seat.activity,
            onTap: () => _editLastAction(seat),
          ),
        ),
        // STRADDLE 행 — v03 cycle 7 #330. tap → toggleStraddleSeat.
        _RowCell(
          label: 'STRADDLE',
          value: isStraddle ? 'ON' : '-',
          dim: !isStraddle,
          highlightColor: isStraddle ? EbsOklch.warn : null,
          onTap: () =>
              ref.read(configProvider.notifier).toggleStraddleSeat(seat.seatNo),
        ),
      ],
    );
  }

  /// D7 — hole card 뒷면(face-down) 만 표시. 카드 값은 노출하지 않는다.
  /// 카드가 분배되었음만 시각화 (운영자가 분배 상태 인지하되 값은 모름).
  Widget _buildHoleCardBack(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: CardColors.cardFaceDown,
                border: Border.all(color: EbsOklch.line, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: EbsOklch.fg2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Dormant helper — reserved for future name-row variant. Cycle 19 U3 토큰
  // 정합만 유지 (LAST 행은 ActionBadge 로 이관).
  // ignore: unused_element
  Widget _buildNameRow(String flag, String name, int seatNo) {
    return Row(
      children: [
        if (flag.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(flag, style: const TextStyle(fontSize: 12)),
          ),
        Expanded(
          child: Text(
            name,
            style: EbsTypography.playerName.copyWith(color: EbsOklch.fg0),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          'S$seatNo',
          style: EbsTypography.shortcutHint.copyWith(color: EbsOklch.fg2),
        ),
      ],
    );
  }

  // D7 — `_buildHoleCards` / `_buildMiniCard` 제거 (2026-04-26 IMPL-007).
  // 이전에는 카드 값(랭크 + 슈트) 을 CC widget 에 표시했으나, 운영자가 카드를
  // 미리 알게 되어 부정 행위 위험. 이제 `_buildHoleCardBack` 만 사용 (face-down).

  // Dormant — reserved for Seat_Management.md §2.3.2 BTN re-assign dialog
  // 진입점 (현재는 dialog 만 보존, chip 자체는 PosBlock 으로 이관 예정).
  // ignore: unused_element
  Widget _buildPositionMarker(String label) {
    final color = _positionColor(label);
    // Position chip 텍스트 — bone-white (BTN) 배경은 진한 텍스트, 그 외는 fg-0.
    final textColor = label == 'BTN' ? EbsOklch.bg0 : EbsOklch.fg0;
    final chip = Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );

    // Seat_Management.md §2.3.2 — BTN chip click → re-assign dialog (IDLE only).
    // SB/BB are derived by Game Engine (§2.3.3 렌더링 책임 분리), not user-editable.
    if (label != 'BTN') return chip;

    return GestureDetector(
      onTap: _onDealerChipTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
    );
  }

  void _onDealerChipTap() {
    final fsm = ref.read(handFsmProvider);
    final isIdle = fsm == HandFsm.idle || fsm == HandFsm.handComplete;
    if (!isIdle) {
      // Seat_Management.md §5.2 — "딜러 위치 변경 ❌ 핸드 내 불변"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('핸드 진행 중에는 딜러 변경 불가 (Seat_Management.md §5.2)'),
          backgroundColor: EbsOklch.err,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    _showDealerReassignDialog();
  }

  Future<void> _showDealerReassignDialog() async {
    final seats = ref.read(seatsProvider);
    final eligible = seats
        .where((s) =>
            s.player != null && s.activity != PlayerActivity.sittingOut)
        .toList();
    if (eligible.isEmpty) return;

    final currentDealer = seats
        .firstWhere((s) => s.isDealer, orElse: () => eligible.first)
        .seatNo;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => _DealerReassignDialog(
        eligible: eligible,
        initialSeat: currentDealer,
      ),
    );
    if (selected == null || selected == currentDealer) return;
    ref.read(seatsProvider.notifier).setDealer(selected);
  }

  // Dormant — generic mini-badge builder kept for reuse.
  // ignore: unused_element
  Widget _buildBadge(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: EbsOklch.fg0,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedBuilder — alias for AnimatedBuilder that accepts Animation directly.
// (Flutter's AnimatedBuilder is actually the class we need.)
// ---------------------------------------------------------------------------
// Note: Flutter's `AnimatedBuilder` is the correct widget. The above usage
// is valid as-is.

// ---------------------------------------------------------------------------
// Dealer re-assign dialog (Seat_Management.md §2.3.2)
// ---------------------------------------------------------------------------

class _DealerReassignDialog extends StatefulWidget {
  const _DealerReassignDialog({
    required this.eligible,
    required this.initialSeat,
  });

  final List<SeatState> eligible;
  final int initialSeat;

  @override
  State<_DealerReassignDialog> createState() => _DealerReassignDialogState();
}

class _DealerReassignDialogState extends State<_DealerReassignDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSeat;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('딜러 재지정 (BTN)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seat_Management.md §2.3.2 — IDLE 상태에서만 변경 가능',
            style: TextStyle(fontSize: 12, color: EbsOklch.fg2),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Dealer 좌석 선택',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in widget.eligible)
                DropdownMenuItem(
                  value: s.seatNo,
                  child: Text('S${s.seatNo} — ${s.player?.name ?? ''}'),
                ),
            ],
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}


class _RowCell extends StatelessWidget {
  const _RowCell({required this.label, required this.value,
    this.big = false, this.mono = false, this.dim = false,
    this.highlightColor, this.onTap});
  final String? label;
  final String value;
  final bool big, mono, dim;
  final Color? highlightColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // Cycle 19 U3 — OKLCH 토큰 정합.
    final c = highlightColor ?? (dim ? EbsOklch.fg3 : EbsOklch.fg0);
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        // `.row-cell` subtle surface — bg-1 @ low alpha (HTML SSOT `--bg-1`).
        color: EbsOklch.bg1.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisAlignment: big ? MainAxisAlignment.center
            : (label == null ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween),
        children: [
          if (label != null && !big)
            Text(label!, style: const TextStyle(fontSize: 9,
              fontWeight: FontWeight.w700, color: EbsOklch.fg3)),
          Flexible(child: Text(value, style: TextStyle(
            fontSize: big ? 22 : 12,
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
            color: c, fontFamily: mono ? 'monospace' : null),
            overflow: TextOverflow.ellipsis, maxLines: 1,
            textAlign: big ? TextAlign.center : TextAlign.right)),
        ])
    );
    final w = Padding(padding: const EdgeInsets.only(bottom: 2), child: body);
    return onTap == null ? w : GestureDetector(onTap: onTap, child: w);
  }
}

class _ActingStrip extends StatelessWidget {
  const _ActingStrip({required this.seat, required this.preHand, required this.onDelete});
  final SeatState seat;
  final bool preHand;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    // Cycle 19 U3 — HTML SSOT `.pcol-acting-strip.{acting|waiting|fold|...}`
    // 매핑. err/accent/warn/fg-3 토큰으로 일원화.
    if (preHand) {
      return GestureDetector(onTap: onDelete,
        child: Container(width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: EbsOklch.err.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3)),
          alignment: Alignment.center,
          child: const Text('DELETE', style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w800, color: EbsOklch.fg0, letterSpacing: 1.0))));
    }
    // 상태별 (label, background tone, foreground text).
    String l;
    Color bg;
    Color fg = EbsOklch.fg0;
    if (seat.activity == PlayerActivity.folded) {
      l = 'FOLD';
      bg = EbsOklch.err.withValues(alpha: 0.55);
      fg = EbsOklch.fg0;
    } else if (seat.activity == PlayerActivity.allIn) {
      l = 'ALL-IN';
      bg = EbsOklch.warn.withValues(alpha: 0.55);
      fg = EbsOklch.bg0;
    } else if (seat.activity == PlayerActivity.sittingOut) {
      l = 'SIT OUT';
      bg = EbsOklch.bg3;
      fg = EbsOklch.fg2;
    } else if (seat.actionOn) {
      // `.pcol-acting-strip.acting` — accent bg + dark warm fg (oklch 0.18 0.04 60).
      l = 'ACTING';
      bg = EbsOklch.accent;
      fg = EbsOklch.bg0;
    } else {
      // `.pcol-acting-strip.waiting` — oklch(0.30 0.015 240) bg + fg-3 text.
      l = 'WAITING';
      bg = EbsOklch.bg3;
      fg = EbsOklch.fg3;
    }
    return Container(width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.center,
      child: Text(l, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w800, color: fg, letterSpacing: 1.0)));
  }
}
