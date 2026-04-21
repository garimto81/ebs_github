// Debug log panel — right-side overlay showing live DebugLog entries.
//
// 표시 조건: debugLogVisibleProvider == true (Ctrl+L 또는 Toolbar 버튼 토글)
// 크기: 우측 420px, 전체 높이
// 내용: DebugLog.snapshot() 기본값 + stream 구독해 실시간 append
// 조작: Clear (버퍼 비우기), Close (visibility false)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/logging/debug_log.dart';
import 'debug_log_provider.dart';

class DebugLogPanel extends ConsumerStatefulWidget {
  const DebugLogPanel({super.key});

  @override
  ConsumerState<DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends ConsumerState<DebugLogPanel> {
  late List<DebugLogEntry> _entries;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _entries = DebugLog.snapshot();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(debugLogVisibleProvider);
    if (!visible) return const SizedBox.shrink();

    ref.listen<AsyncValue<DebugLogEntry>>(debugLogStreamProvider, (_, next) {
      next.whenData((entry) {
        setState(() {
          _entries = DebugLog.snapshot();
        });
        _scrollToBottom();
      });
    });

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 420,
      child: Material(
        elevation: 8,
        color: const Color(0xFF1E1E1E),
        child: Column(
          children: [
            _Header(
              onClear: () {
                DebugLog.clear();
                setState(() => _entries = []);
              },
              onClose: () =>
                  ref.read(debugLogVisibleProvider.notifier).state = false,
              count: _entries.length,
            ),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        '(no log entries — press NEW HAND or wait)',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) => _LogRow(entry: _entries[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClear,
    required this.onClose,
    required this.count,
  });

  final VoidCallback onClear;
  final VoidCallback onClose;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF2D2D2D),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            'DEBUG LOG  ($count)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            tooltip: 'Close (Ctrl+L)',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});
  final DebugLogEntry entry;

  Color get _levelColor {
    switch (entry.level) {
      case DebugLogLevel.d:
        return Colors.white60;
      case DebugLogLevel.i:
        return Colors.lightBlueAccent;
      case DebugLogLevel.w:
        return Colors.orangeAccent;
      case DebugLogLevel.e:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = entry.timestamp.toIso8601String().substring(11, 23);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.white70,
            height: 1.3,
          ),
          children: [
            TextSpan(
                text: '$ts  ',
                style: const TextStyle(color: Colors.white38)),
            TextSpan(
              text: '[${entry.levelChar}] ',
              style: TextStyle(color: _levelColor, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: '${entry.category}: ',
              style: const TextStyle(color: Colors.cyanAccent),
            ),
            TextSpan(text: entry.message),
            if (entry.data != null)
              TextSpan(
                text: '  ${entry.data}',
                style: const TextStyle(color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}
