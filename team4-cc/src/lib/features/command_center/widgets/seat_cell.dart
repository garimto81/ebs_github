// M-05 Seat Cell widget (BS-05-03 §시각 규격, CCR-032).
// Uses SeatColors SSOT from foundation/theme for CC-Overlay consistency.
//
// UI-02 변경 (2026-04-13):
// - 국기 추가 (country_code → Flag emoji/icon)
// - Equity: '%' 숫자만 (프로그레스 바 제거)
// - 인라인 편집: 각 요소 탭 → 수정 다이얼로그 (화면 2 좌석 상세 패널 대체)
// - 수동 편집 우선 원칙: 동기화 아이콘(🔄)으로 DB 값 수용/거부 제어
// - 좌석 번호: S1~S10 (기존 S0~S9에서 변경)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/theme/seat_colors.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

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

class _SeatCellState extends ConsumerState<SeatCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: SeatColors.actionGlowDuration,
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
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
        color: Colors.white24,
        width: 1.0,
        // Dashed border simulated via CustomPaint below for empty seats.
      );
    }
    if (seat.activity == PlayerActivity.allIn) {
      return const BorderSide(color: Color(0xFFFFD700), width: 2.0); // gold
    }
    return const BorderSide(color: Colors.white24, width: 1.0);
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
              leading: const Icon(Icons.person_remove, color: Colors.red),
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
            child: const Text('Vacate', style: TextStyle(color: Colors.red)),
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

    final Widget cell = AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowShadows = seat.actionOn
            ? [
                BoxShadow(
                  color: SeatColors.actionGlowTo
                      .withValues(alpha: _glowAnimation.value),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : <BoxShadow>[];

        return Container(
          width: EbsSpacing.seatCellWidth,
          height: EbsSpacing.seatCellHeight,
          decoration: BoxDecoration(
            color: bgColor,
            border: seat.isEmpty
                ? _dashedBorder()
                : Border.fromBorderSide(border),
            borderRadius: BorderRadius.circular(6),
            boxShadow: glowShadows,
          ),
          child: child,
        );
      },
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'S${widget.seatIndex}',
            style: EbsTypography.infoBar.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            'Empty',
            style: EbsTypography.shortcutHint.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  BoxBorder _dashedBorder() {
    // Flutter does not natively support dashed borders. Use a solid border
    // with reduced opacity as an approximation. A full dashed border would
    // require CustomPaint, which is deferred to a polish pass.
    return Border.all(color: Colors.white24, width: 1.0);
  }

  // -- occupied seat --------------------------------------------------------

  Widget _buildOccupiedSeat(SeatState seat) {
    final player = seat.player!;
    final flag = _countryFlag(player.countryCode);
    final posLabel = _positionLabel(seat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Flag + Name + Seat #
        _buildNameRow(flag, player.name, seat.seatNo),

        const Divider(height: 4, thickness: 0.5, color: Colors.white24),

        // Row 2: Stack
        GestureDetector(
          onTap: () => _editStack(seat),
          child: Text(
            '\$${_formatStack(player.stack)}',
            style: EbsTypography.stackAmount.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Row 3: D7 (회의 2026-04-22) — CC 운영자(딜러)는 hole cards 비노출.
        // 데이터(`seat.holeCards`) 는 Overlay 송출용으로 state 에 보존되며,
        // CC widget 트리에서는 절대 렌더링하지 않는다 (`tools/check_cc_no_holecard.py` CI 가드).
        // 이 위치에 hole card 위젯을 추가하면 운영자가 카드를 미리 알게 되어
        // 부정 행위 위험 발생. SG-021 / Foundation §5.4 / IMPL-007 참조.
        if (seat.holeCards.isNotEmpty) _buildHoleCardBack(seat.holeCards.length),

        // Row 4: Position marker or sitting-out badge
        if (seat.activity == PlayerActivity.sittingOut)
          _buildBadge('Sitting Out', Colors.orange)
        else if (posLabel != null)
          _buildPositionMarker(posLabel),
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
                color: Colors.blueGrey.shade800,
                border: Border.all(color: Colors.white24, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
            style: EbsTypography.playerName.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          'S$seatNo',
          style: EbsTypography.shortcutHint.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  // D7 — `_buildHoleCards` / `_buildMiniCard` 제거 (2026-04-26 IMPL-007).
  // 이전에는 카드 값(랭크 + 슈트) 을 CC widget 에 표시했으나, 운영자가 카드를
  // 미리 알게 되어 부정 행위 위험. 이제 `_buildHoleCardBack` 만 사용 (face-down).

  Widget _buildPositionMarker(String label) {
    final chip = Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: _positionColor(label),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
        SnackBar(
          content: const Text('핸드 진행 중에는 딜러 변경 불가 (Seat_Management.md §5.2)'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
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
            color: Colors.white,
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
            style: TextStyle(fontSize: 12, color: Colors.black54),
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
