// EBS Lobby — small chrome primitives shared across TopBar / SideRail /
// Breadcrumb / KPI strip.
//
// Pulsing live dot is the design's signature on-air indicator (see
// `.cc-pill .pulse` keyframe in styles.css).

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A pulsing live-green dot. Pulses outward at the same cadence as the CSS
/// `.pulse` keyframe (1.8s ease-out infinite).
class PulsingLiveDot extends StatefulWidget {
  const PulsingLiveDot({super.key, this.size = 7, this.color});
  final double size;
  final Color? color;

  @override
  State<PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? DesignTokens.liveBase;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final t = _ctl.value;
        final ringSize = widget.size + 16 * t;
        final ringAlpha = (1.0 - t).clamp(0.0, 1.0) * 0.55;
        return SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: base.withValues(alpha: ringAlpha),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: base,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Status badge (pill) — used for event/flight/table status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.ink,
    required this.dot,
  });

  final String label;
  final Color bg;
  final Color ink;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02 * 10.5,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
