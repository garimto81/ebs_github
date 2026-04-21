// Debug log panel visibility + stream providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/logging/debug_log.dart';

/// Controls visibility of [DebugLogPanel] overlay.
/// Toggled by Ctrl+L keyboard shortcut or Toolbar button.
final debugLogVisibleProvider = StateProvider<bool>((ref) => false);

/// Live stream of new entries for real-time panel updates.
final debugLogStreamProvider = StreamProvider<DebugLogEntry>(
  (ref) => DebugLog.stream,
);
