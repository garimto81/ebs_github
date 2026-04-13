// Layer 1: Player Info (name, stack, photo, position marker).
// Uses SeatColors SSOT — CC-Overlay visual consistency (CCR-034).

import 'package:flutter/material.dart';

import '../../../foundation/theme/seat_colors.dart';

class PlayerInfoLayer extends StatelessWidget {
  const PlayerInfoLayer({super.key, required this.seatNo});

  final int seatNo;

  @override
  Widget build(BuildContext context) => Container(
        color: SeatColors.active,
        child: Text('Seat $seatNo'),
      );
}
