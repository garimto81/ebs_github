// Seat entity stub. See BS-05-03 and DATA-02 §Seat.

import '../enums/seat_status.dart';
import 'player.dart';

class Seat {
  const Seat({
    required this.seatNo,
    required this.fsm,
    this.player,
    this.activity,
    this.actionOn = false,
  });

  final int seatNo;
  final SeatFsm fsm;
  final Player? player;
  final PlayerActivity? activity;
  final bool actionOn;
}
