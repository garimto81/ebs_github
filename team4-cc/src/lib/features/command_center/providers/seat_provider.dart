// Seat state provider — 10 seats with SeatFSM + player activity.
// See BS-05-03-seat-management.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/entities/seat.dart';
import '../../../models/enums/seat_status.dart';

final seatsProvider = StateProvider<List<Seat>>((ref) {
  return List.generate(
    10,
    (i) => Seat(seatNo: i, fsm: SeatFsm.vacant),
  );
});
