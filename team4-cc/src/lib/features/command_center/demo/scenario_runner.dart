// Scenario runner for Demo Mode (Demo_Test_Mode.md §3.3).
//
// Drives a DemoScenario step-by-step or auto-play through
// local_dispatcher, updating DemoProvider state as it goes.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/demo_provider.dart';
import 'local_dispatcher.dart';
import 'scenarios.dart';

class ScenarioRunner {
  ScenarioRunner(this._container);

  final ProviderContainer _container;
  DemoScenario? _scenario;
  int _stepIndex = 0;
  Timer? _autoTimer;

  /// Load a scenario for execution.
  void load(DemoScenario scenario) {
    stop();
    _scenario = scenario;
    _stepIndex = 0;
    _container.read(demoProvider.notifier)
      ..setScenario(scenario.name, scenario.events.length)
      ..clearLog()
      ..log('System', '시나리오 로드: ${scenario.name}');
  }

  /// Execute the next single step. Returns false if scenario is complete.
  bool step() {
    final scenario = _scenario;
    if (scenario == null || _stepIndex >= scenario.events.length) {
      _onComplete();
      return false;
    }

    final event = scenario.events[_stepIndex];
    _executeEvent(event);
    _stepIndex++;
    _container.read(demoProvider.notifier).advanceStep();
    return _stepIndex < scenario.events.length;
  }

  /// Auto-play all remaining steps with delays.
  void play() {
    final scenario = _scenario;
    if (scenario == null || _stepIndex >= scenario.events.length) return;

    _container.read(demoProvider.notifier).setRunning(true);
    _scheduleNext();
  }

  /// Stop auto-play.
  void stop() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _container.read(demoProvider.notifier).setRunning(false);
  }

  /// Reset scenario to beginning + clear demo state.
  void reset() {
    stop();
    _stepIndex = 0;
    resetDemoState(_container);
    seedDemoPlayers(_container);
    final scenario = _scenario;
    if (scenario != null) {
      _container.read(demoProvider.notifier)
        ..setScenario(scenario.name, scenario.events.length)
        ..clearLog()
        ..log('System', '리셋 완료');
    }
  }

  /// Whether a scenario is loaded.
  bool get hasScenario => _scenario != null;

  /// Whether auto-play is running.
  bool get isRunning => _autoTimer != null;

  /// Current step index.
  int get currentStep => _stepIndex;

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _executeEvent(DemoEvent event) {
    dispatchLocalEvent(_container, event.payload);
    _container.read(demoProvider.notifier).log(
      event.type,
      event.uiHint ?? event.type,
    );
  }

  void _scheduleNext() {
    final scenario = _scenario;
    if (scenario == null || _stepIndex >= scenario.events.length) {
      _onComplete();
      return;
    }

    final event = scenario.events[_stepIndex];
    _autoTimer = Timer(event.delay, () {
      _executeEvent(event);
      _stepIndex++;
      _container.read(demoProvider.notifier).advanceStep();

      if (_stepIndex < scenario.events.length) {
        _scheduleNext();
      } else {
        _onComplete();
      }
    });
  }

  void _onComplete() {
    stop();
    _container.read(demoProvider.notifier).log('System', '시나리오 완료');
  }

  /// Clean up resources.
  void dispose() {
    _autoTimer?.cancel();
  }
}
