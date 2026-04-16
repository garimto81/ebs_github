// Demo Mode state management (Demo_Test_Mode.md §1-§8).
//
// Tracks whether demo mode is active, the current scenario, step index,
// and the event log for the control panel display.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/configs/features.dart';
import '../../../models/enums/hand_fsm.dart';
import '../demo/local_dispatcher.dart';
import 'hand_fsm_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DemoState {
  const DemoState({
    this.isActive = false,
    this.isRunning = false,
    this.currentScenarioName,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.eventLog = const [],
  });

  final bool isActive;
  final bool isRunning; // auto-play in progress
  final String? currentScenarioName;
  final int currentStep;
  final int totalSteps;
  final List<DemoLogEntry> eventLog;

  DemoState copyWith({
    bool? isActive,
    bool? isRunning,
    String? currentScenarioName,
    int? currentStep,
    int? totalSteps,
    List<DemoLogEntry>? eventLog,
  }) =>
      DemoState(
        isActive: isActive ?? this.isActive,
        isRunning: isRunning ?? this.isRunning,
        currentScenarioName: currentScenarioName ?? this.currentScenarioName,
        currentStep: currentStep ?? this.currentStep,
        totalSteps: totalSteps ?? this.totalSteps,
        eventLog: eventLog ?? this.eventLog,
      );
}

class DemoLogEntry {
  const DemoLogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  final DateTime timestamp;
  final String type; // HandStarted, ActionPerformed, etc.
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DemoNotifier extends StateNotifier<DemoState> {
  DemoNotifier(this._container) : super(const DemoState());

  final ProviderContainer _container;

  /// Activate demo mode (Demo_Test_Mode.md §1.3).
  void activate() {
    Features.enableDemoMode = true;
    seedDemoPlayers(_container);
    state = state.copyWith(isActive: true);
  }

  /// Deactivate demo mode.
  /// Only allowed when hand is not in progress (§8).
  bool deactivate() {
    final fsm = _container.read(handFsmProvider);
    if (fsm != HandFsm.idle && fsm != HandFsm.handComplete) {
      return false; // cannot deactivate during hand
    }
    resetDemoState(_container);
    Features.enableDemoMode = false;
    state = const DemoState();
    return true;
  }

  /// Log an event to the control panel display.
  void log(String type, String message) {
    final entry = DemoLogEntry(
      timestamp: DateTime.now(),
      type: type,
      message: message,
    );
    final newLog = [...state.eventLog, entry];
    // Keep last 50 entries (§5.2).
    final trimmed = newLog.length > 50
        ? newLog.sublist(newLog.length - 50)
        : newLog;
    state = state.copyWith(eventLog: trimmed);
  }

  /// Update scenario tracking state.
  void setScenario(String name, int totalSteps) {
    state = state.copyWith(
      currentScenarioName: name,
      currentStep: 0,
      totalSteps: totalSteps,
    );
  }

  /// Advance step counter.
  void advanceStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Set auto-play running state.
  void setRunning(bool running) {
    state = state.copyWith(isRunning: running);
  }

  /// Clear event log.
  void clearLog() {
    state = state.copyWith(eventLog: []);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Demo state provider.
///
/// Uses a ProviderContainer-aware notifier so it can seed/reset other
/// providers during activate/deactivate. The container is injected at
/// creation time and must match the app's root ProviderScope.
final demoProvider = StateNotifierProvider<DemoNotifier, DemoState>((ref) {
  // Access the container via a workaround: create the notifier with a
  // placeholder and let it be overridden at app startup when demo mode
  // is detected. For widget-tree usage, the ProviderScope's container
  // is accessed via ref's internal container reference.
  //
  // In practice, the DemoControlPanel will use ref.read to dispatch
  // events through local_dispatcher functions that take ProviderContainer.
  return DemoNotifier(ProviderContainer());
});
