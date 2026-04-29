// EBS Lobby — Waitlist drawer (`.waitlist` in design source).
//
// 240px right-docked side panel, used inside TablesScreen. Contains a
// numbered list of waiting players, rendered with hover highlight and
// a pinned hint at the bottom.

import 'package:flutter/material.dart';

import '../../../foundation/theme/design_tokens.dart';

class WaitlistDrawer extends StatelessWidget {
  const WaitlistDrawer({
    super.key,
    required this.names,
    this.assignHint = 'Drag a name onto a seat to assign.',
  });

  final List<String> names;
  final String assignHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DesignChrome.waitlistWidth,
      decoration: const BoxDecoration(
        color: DesignTokens.lightBgAlt,
        border: Border(
          left: BorderSide(color: DesignTokens.lightLine),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(count: names.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: names.length,
              itemBuilder: (_, i) => _Row(index: i, name: names[i]),
            ),
          ),
          _Hint(text: assignHint),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.lightLine),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Text(
            'WAITING LIST',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 10,
              color: DesignTokens.lightInk3,
              letterSpacing: 0.14 * 10,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DesignTokens.lightInk,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.index, required this.name});
  final int index;
  final String name;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: _hovered ? DesignTokens.lightBgSunken : Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                (widget.index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamilyMono,
                  fontSize: 11,
                  color: DesignTokens.lightInk4,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamilyUi,
                  fontSize: 12,
                  color: DesignTokens.lightInk2,
                ),
              ),
            ),
            if (_hovered)
              const Text(
                'drag →',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamilyUi,
                  fontSize: 10,
                  color: DesignTokens.lightInk4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: DesignTokens.lightBgSunken,
        border: Border(
          top: BorderSide(color: DesignTokens.lightLine),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 10,
          color: DesignTokens.lightInk4,
        ),
      ),
    );
  }
}
