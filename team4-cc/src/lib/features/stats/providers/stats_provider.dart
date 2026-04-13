// Stats provider — 10-seat VPIP/PFR/3Bet/AF/Hands/PL feed (BS-05-07).

import 'package:flutter_riverpod/flutter_riverpod.dart';

final statsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => const []);
