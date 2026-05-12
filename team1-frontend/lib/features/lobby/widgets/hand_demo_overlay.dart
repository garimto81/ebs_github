// Cycle 6 (#312) — Lobby multi-hand auto_demo visual overlay.
//
// Rendered when --dart-define=HAND_AUTO_SETUP=true. Sits on top of all
// routes (above login screen too) so evidence capture works even when
// the backend is unreachable (Cycle 4 partial — backend timeout case).
//
// Composition:
//   ┌──────────────────────────────────────────────────────────┐
//   │ Hand #N  •  step: <state>            cascade:lobby-... ▸ │
//   │                                                          │
//   │  [seat 1]  [seat 2]  [seat 3]  [seat 4]  [seat 5]  [seat 6]
//   │     D                                                    │
//   │                                                          │
//   │  Pot: 240        Last hand: #1 seat 1 won 240            │
//   └──────────────────────────────────────────────────────────┘
//
// Visible on EVERY screen during the demo run — useful as a debug HUD
// and as the Cycle 6 evidence target.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hand_auto_setup_provider.dart';
import 'dealer_button_indicator.dart';

class HandDemoOverlay extends ConsumerWidget {
  const HandDemoOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(handAutoSetupProvider);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE6101820),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(s),
            const SizedBox(height: 8),
            _seatRow(s),
            const SizedBox(height: 8),
            _statusRow(s),
            if (s.handHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              _historyPanel(s.handHistory),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow(HandAutoSetupState s) {
    return Row(
      children: [
        const Icon(Icons.casino, color: Colors.tealAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          'Hand #${s.handNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        _stepChip(s.step),
        const Spacer(),
        if (s.message != null)
          Flexible(
            child: Text(
              s.message!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }

  Widget _seatRow(HandAutoSetupState s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= s.maxSeats; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          _SeatChip(seatNo: i, isDealer: i == s.dealerSeat),
        ],
      ],
    );
  }

  Widget _statusRow(HandAutoSetupState s) {
    return Row(
      children: [
        const Icon(Icons.attach_money, color: Colors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          'Pot: ${s.currentPot}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 16),
        Icon(Icons.location_on,
            color: Colors.tealAccent.shade400, size: 14),
        const SizedBox(width: 4),
        Text(
          'Dealer seat: ${s.dealerSeat}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 16),
        Text(
          'maxSeats: ${s.maxSeats}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _historyPanel(List<HandHistoryEntry> history) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history,
                  color: Colors.white.withValues(alpha: 0.7), size: 14),
              const SizedBox(width: 6),
              Text(
                'Hand history (${history.length})',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final h in history.reversed.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '  • #${h.handNumber} — seat ${h.winnerSeat} (${h.winnerName}) '
                'won ${h.pot}   dealer=${h.dealerSeat}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepChip(HandAutoSetupStep step) {
    final color = _stepColor(step);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        step.name,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Color _stepColor(HandAutoSetupStep step) {
    switch (step) {
      case HandAutoSetupStep.pending:
        return Colors.grey;
      case HandAutoSetupStep.failed:
        return Colors.redAccent;
      case HandAutoSetupStep.hand2Dealt:
      case HandAutoSetupStep.cascadeReady:
        return Colors.greenAccent;
      case HandAutoSetupStep.hand1Complete:
        return Colors.amberAccent;
      case HandAutoSetupStep.nextHandRotating:
        return Colors.cyanAccent;
      default:
        return Colors.lightBlueAccent;
    }
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.seatNo, required this.isDealer});

  final int seatNo;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDealer
                ? Colors.tealAccent.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDealer
                  ? Colors.tealAccent
                  : Colors.white.withValues(alpha: 0.25),
              width: isDealer ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$seatNo',
            style: TextStyle(
              color: isDealer ? Colors.tealAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        if (isDealer)
          Positioned(
            top: -8,
            right: -8,
            child: DealerButtonIndicator.small(),
          ),
      ],
    );
  }
}
