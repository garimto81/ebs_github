// Layer 1: Outs (remaining beneficial cards count, auto from Engine).
//
// Small badge: "12 outs". Only visible when equity is being calculated.

import 'package:flutter/material.dart';

/// Displays the count of remaining outs (beneficial cards).
///
/// - [outsCount] null: not applicable / not visible
/// - [outsCount] 0+: displayed as "N outs"
class OutsLayer extends StatelessWidget {
  const OutsLayer({
    super.key,
    this.outsCount,
  });

  /// Number of outs. null = not applicable (hidden).
  final int? outsCount;

  @override
  Widget build(BuildContext context) {
    if (outsCount == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC1E88E5), // Blue with slight transparency
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$outsCount outs',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
