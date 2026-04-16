// Demo Mode control panel (Demo_Test_Mode.md §2).
//
// Collapsible panel below toolbar with scenario controls, player
// management, and real-time event log. Visually distinct from
// production UI via orange accent color.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo/scenario_runner.dart';
import '../demo/scenarios.dart';
import '../providers/demo_provider.dart';

// ---------------------------------------------------------------------------
// Panel colors (§7)
// ---------------------------------------------------------------------------

const _demoBannerColor = Color(0xFFE65100);
const _demoPanelBg = Color(0xFF2A1800);
const _demoAccent = Color(0xFFFFA726);

// ---------------------------------------------------------------------------
// Demo Control Panel
// ---------------------------------------------------------------------------

class DemoControlPanel extends ConsumerStatefulWidget {
  const DemoControlPanel({super.key, required this.runner});

  final ScenarioRunner runner;

  @override
  ConsumerState<DemoControlPanel> createState() => _DemoControlPanelState();
}

class _DemoControlPanelState extends ConsumerState<DemoControlPanel> {
  bool _expanded = true;
  DemoScenario _selected = builtInScenarios.first;

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoProvider);
    if (!demo.isActive) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // -- Banner bar (always visible) --
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            height: 32,
            color: _demoBannerColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                if (demo.currentScenarioName != null)
                  Text(
                    '${demo.currentScenarioName} — '
                    'Step ${demo.currentStep}/${demo.totalSteps}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // -- Expandable control area --
        if (_expanded)
          Container(
            color: _demoPanelBg,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScenarioRow(demo),
                const SizedBox(height: 8),
                _buildPlayerRow(),
                const SizedBox(height: 8),
                _buildEventLog(demo),
              ],
            ),
          ),
      ],
    );
  }

  // -- Scenario controls (§2.2) --
  Widget _buildScenarioRow(DemoState demo) {
    return Row(
      children: [
        const Text('시나리오', style: TextStyle(color: _demoAccent, fontSize: 12)),
        const SizedBox(width: 8),
        DropdownButton<DemoScenario>(
          value: _selected,
          dropdownColor: _demoPanelBg,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          underline: Container(height: 1, color: _demoAccent),
          items: builtInScenarios
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (s) {
            if (s == null) return;
            setState(() => _selected = s);
            widget.runner.load(s);
          },
        ),
        const SizedBox(width: 12),
        _DemoButton(
          icon: Icons.play_arrow,
          label: '실행',
          enabled: !demo.isRunning,
          onPressed: () {
            if (!widget.runner.hasScenario) widget.runner.load(_selected);
            widget.runner.play();
          },
        ),
        _DemoButton(
          icon: Icons.skip_next,
          label: '스텝',
          enabled: !demo.isRunning,
          onPressed: () {
            if (!widget.runner.hasScenario) widget.runner.load(_selected);
            widget.runner.step();
          },
        ),
        _DemoButton(
          icon: Icons.stop,
          label: '정지',
          enabled: demo.isRunning,
          onPressed: widget.runner.stop,
        ),
        _DemoButton(
          icon: Icons.replay,
          label: '리셋',
          enabled: true,
          onPressed: widget.runner.reset,
        ),
      ],
    );
  }

  // -- Player management (§4.1) --
  Widget _buildPlayerRow() {
    return Row(
      children: [
        const Text('플레이어', style: TextStyle(color: _demoAccent, fontSize: 12)),
        const SizedBox(width: 8),
        _DemoButton(
          icon: Icons.person_add,
          label: '3인 세팅',
          enabled: true,
          onPressed: () {
            // Use the existing seed function via runner reset
            widget.runner.reset();
          },
        ),
      ],
    );
  }

  // -- Event log (§5) --
  Widget _buildEventLog(DemoState demo) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: demo.eventLog.length,
        itemBuilder: (_, i) {
          final entry = demo.eventLog[demo.eventLog.length - 1 - i];
          final timeStr =
              '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
              '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
              '${entry.timestamp.second.toString().padLeft(2, '0')}';
          return Text(
            '[$timeStr] ${entry.message}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _logColor(entry.type),
            ),
          );
        },
      ),
    );
  }

  Color _logColor(String type) {
    return switch (type) {
      'HandStarted' => const Color(0xFF66BB6A),
      'HandEnded' => const Color(0xFF66BB6A),
      'ActionPerformed' => Colors.white70,
      'CardDetected' => const Color(0xFFFDD835),
      'RfidStatusChanged' => const Color(0xFFEF5350),
      'System' => const Color(0xFF42A5F5),
      _ => Colors.white54,
    };
  }
}

// ---------------------------------------------------------------------------
// Small demo button
// ---------------------------------------------------------------------------

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: _demoAccent,
          disabledForegroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
