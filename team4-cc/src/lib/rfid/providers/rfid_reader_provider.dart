// Riverpod DI for IRfidReader (team4-cc/CLAUDE.md §RFID HAL 규칙).
//
// Business logic (seat_provider, hand_fsm_provider, etc.) MUST resolve
// IRfidReader via this provider. Direct instantiation is prohibited.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/configs/features.dart';
import '../abstract/i_rfid_reader.dart';
import '../mock/mock_rfid_reader.dart';
import '../real/st25r3911b_reader.dart';

final rfidReaderProvider = Provider<IRfidReader>((ref) {
  if (Features.useMockRfid) {
    return MockRfidReader();
  }
  // TODO(Phase 2): detect chip (ST25R3911B vs ST25R3916) and return
  // appropriate concrete reader (CCR-022 §13 migration path).
  return St25r3911bReader();
});
