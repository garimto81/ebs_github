// EBS Lobby — sticky breadcrumb bar (44px).
//
// Mirrors `.bc-bar` / `.bc` / `.bc-actions` from the design source. Each
// crumb is a clickable navigation hop; the last crumb is rendered as the
// current page with bold ink. The right side carries a `⌘K` keyboard hint.

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
    this.shortcutHint = '⌘K',
    this.shortcutLabel = 'to jump',
  });

  final List<LobbyBreadcrumbCrumb> crumbs;
  final String shortcutHint;
  final String shortcutLabel;

  @override
  Size get preferredSize =>
      const Size.fromHeight(DesignChrome.breadcrumbHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: DesignChrome.breadcrumbHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _Trail(crumbs: crumbs)),
          _Shortcut(hint: shortcutHint, label: shortcutLabel),
        ],
      ),
    );
  }
}

class _Trail extends StatelessWidget {
  const _Trail({required this.crumbs});
  final List<LobbyBreadcrumbCrumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (var i = 0; i < crumbs.length; i++) {
      final c = crumbs[i];
      final isLast = i == crumbs.length - 1;
      if (i > 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right,
              size: 14,
              color: DesignTokens.lightInk5,
            ),
          ),
        );
      }
      children.add(
        _Crumb(
          label: c.label,
          onTap: c.onTap,
          current: isLast,
          textTheme: theme,
        ),
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
    required this.textTheme,
  });

  final String label;
  final VoidCallback? onTap;
  final bool current;
  final ThemeData textTheme;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? textTheme.colorScheme.onSurface
        : DesignTokens.lightInk3;
    final style = TextStyle(
      fontFamily: DesignTokens.fontFamilyUi,
      fontSize: DesignTokens.fsTab,
      color: color,
      fontWeight: current ? FontWeight.w600 : FontWeight.w500,
    );
    final text = Text(label, style: style);
    if (onTap == null) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: text),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.hint, required this.label});
  final String hint;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius:
                BorderRadius.circular(DesignChrome.buttonBorderRadius - 1),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            hint,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              fontSize: 10,
              color: DesignTokens.lightInk3,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyUi,
            fontSize: 11,
            color: DesignTokens.lightInk3,
          ),
        ),
      ],
    );
  }
}
