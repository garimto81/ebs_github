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
import '../../../models/enums/seat_status.dart';
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

/// Suit character → display symbol + color.
({String symbol, Color color}) _suitDisplay(String suit) {
  return switch (suit) {
    's' => (symbol: '♠', color: Colors.black),
    'h' => (symbol: '♥', color: Colors.red),
    'd' => (symbol: '♦', color: Colors.blue),
    'c' => (symbol: '♣', color: Colors.green),
    _ => (symbol: suit, color: Colors.white),
  };
}

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

        // Row 3: Hole cards (if any)
        if (seat.holeCards.isNotEmpty) _buildHoleCards(seat.holeCards),

        // Row 4: Position marker or sitting-out badge
        if (seat.activity == PlayerActivity.sittingOut)
          _buildBadge('Sitting Out', Colors.orange)
        else if (posLabel != null)
          _buildPositionMarker(posLabel),
      ],
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

  Widget _buildHoleCards(List<HoleCard> cards) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _buildMiniCard(cards[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniCard(HoleCard card) {
    final suit = _suitDisplay(card.suit);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.rank,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            suit.symbol,
            style: TextStyle(fontSize: 12, color: suit.color),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionMarker(String label) {
    return Padding(
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
