// Action button state provider (BS-05-02, CCR-031).
//
// Computes enabled/disabled for FOLD/CHECK/CALL/BET/RAISE/ALL-IN based on
// HandFSM × biggest_bet × current_bet × stack AND `ActionOnResponse` received.
// Label dynamically switches CHECK↔CALL, BET↔RAISE-TO via BiggestBet.

import 'package:flutter_riverpod/flutter_riverpod.dart';

final actionOnReceivedProvider = StateProvider<bool>((ref) => false);
