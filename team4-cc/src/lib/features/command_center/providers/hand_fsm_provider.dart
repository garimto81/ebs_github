// HandFSM provider — tracks current hand lifecycle state (BS-05-01).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/hand_fsm.dart';

final handFsmProvider = StateProvider<HandFsm>((ref) => HandFsm.idle);
