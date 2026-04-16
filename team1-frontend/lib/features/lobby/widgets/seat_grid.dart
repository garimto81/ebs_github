import 'package:flutter/material.dart';

/// Seat status for a single seat cell.
enum SeatCellStatus { occupied, empty, busted }

/// Data for a single seat in the grid.
class SeatInfo {
  final int seatIndex;
  final SeatCellStatus status;
  final int? playerId;
  final String? playerName;

  const SeatInfo({
    required this.seatIndex,
    required this.status,
    this.playerId,
    this.playerName,
  });
}

/// Compact colored seat cells for a table row (WSOP LIVE style).
///
/// Used inside TableListScreen DataTable rows. Each cell is a small
/// colored square: green = seated, grey = empty, red = busted.
class SeatGrid extends StatelessWidget {
  final List<SeatInfo> seats;
  final int maxSeats;

  const SeatGrid({
    super.key,
    required this.seats,
    required this.maxSeats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxSeats; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          _SeatCell(seat: i < seats.length ? seats[i] : null, index: i),
        ],
      ],
    );
  }
}

class _SeatCell extends StatelessWidget {
  final SeatInfo? seat;
  final int index;

  const _SeatCell({required this.seat, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = seat?.status ?? SeatCellStatus.empty;

    final Color bgColor;
    final String label;
    switch (status) {
      case SeatCellStatus.occupied:
        bgColor = Colors.green.shade400;
        label = seat?.playerId != null ? '#${seat!.playerId}' : '';
      case SeatCellStatus.busted:
        bgColor = Colors.red.shade300;
        label = '\u2715'; // ✕
      case SeatCellStatus.empty:
        bgColor = Colors.grey.shade200;
        label = '';
    }

    return Tooltip(
      message: seat?.playerName != null
          ? 'Seat $index: ${seat!.playerName}'
          : 'Seat $index: ${status.name}',
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Legend row for seat status colors.
class SeatGridLegend extends StatelessWidget {
  const SeatGridLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendItem(Colors.green.shade400, 'Seated'),
        const SizedBox(width: 12),
        _legendItem(Colors.grey.shade200, 'Empty'),
        const SizedBox(width: 12),
        _legendItem(Colors.red.shade300, 'Busted'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
