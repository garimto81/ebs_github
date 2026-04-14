// Hand-level display state providers (AT-01 Info Bar / Board area).
//
// Extracted from at_01_main_screen.dart so that ws_provider.dart can update
// these state slices without creating a circular import.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current hand number (incremented by engine on new hand).
final handNumberProvider = StateProvider<int>((ref) => 0);

/// Current pot total (updated per action from engine).
final potTotalProvider = StateProvider<int>((ref) => 0);

/// Community board cards (up to 5). Empty string = face-down slot.
final boardCardsProvider = StateProvider<List<String>>((ref) => const []);
