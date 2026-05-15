// EBS Lobby — sticky breadcrumb bar (28px).
//
// HTML mockup: `.bc-bar { padding: 6px 16px; font-size: 10px; border-bottom: 1px solid #eee }`
// Each crumb is a clickable navigation hop; the last crumb is bold (current page).
// ⌘K shortcut hint removed — not present in HTML mockup.

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class LobbyBreadcrumbCrumb {
  const LobbyBreadcrumbCrumb({
    required this.label,
    this.onTap,
  });

  /// Display label for the crumb.
  final String label;

  /// Tap handler — null for the current (terminal) crumb.
  final VoidCallback? onTap;
}

class LobbyBreadcrumb extends StatelessWidget implements PreferredSizeWidget {
  const LobbyBreadcrumb({
    super.key,
    required this.crumbs,
  });

  final List<LobbyBreadcrumbCrumb> crumbs;

  @override
  Size get preferredSize =>
      const Size.fromHeight(DesignChrome.breadcrumbHeight); // 28px

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesignChrome.breadcrumbHeight,
      // HTML: `padding: 6px 16px`
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        // HTML: pure white background (`#fff`), not warm-tinted
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Trail(crumbs: crumbs),
      ),
    );
  }
}

class _Trail extends StatelessWidget {
  const _Trail({required this.crumbs});
  final List<LobbyBreadcrumbCrumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < crumbs.length; i++) {
      final c = crumbs[i];
      final isLast = i == crumbs.length - 1;
      if (i > 0) {
        // HTML uses `›` text separator — lighter than chevron icon
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '›',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFBBBBBB),
              ),
            ),
          ),
        );
      }
      children.add(
        _Crumb(label: c.label, onTap: c.onTap, current: isLast),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.onTap,
    required this.current,
  });

  final String label;
  final VoidCallback? onTap;
  final bool current;

  @override
  Widget build(BuildContext context) {
    // HTML: `font-size: 10px`, active crumb bold
    final style = TextStyle(
      fontFamily: DesignTokens.fontFamilyUi,
      fontSize: 10,
      color: current ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
    );
    final text = Text(label, style: style);
    if (onTap == null) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: text),
    );
  }
}
