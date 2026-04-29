// EBS Lobby — collapsible side rail (240/56px).
//
// Mirrors `.rail` / `.rail-section` / `.rail-item` from the design source.
// Always uses the dark `--rail-bg` palette regardless of light/dark theme so
// the navigation surface is consistent across modes.
//
// The rail is layout-driven, not router-driven: callers pass [items] and a
// [selectedId] / [onSelect] callback so it stays compatible with both
// go_router and ad-hoc state machines.

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class LobbySideRailItem {
  const LobbySideRailItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badge,
    this.section,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Optional right-aligned count badge. Hidden when collapsed.
  final int? badge;

  /// When non-null, this item is preceded by a section heading.
  final String? section;
}

class LobbySideRail extends StatelessWidget {
  const LobbySideRail({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.collapsed = false,
    this.footerVersion,
  });

  final List<LobbySideRailItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool collapsed;
  final String? footerVersion;

  @override
  Widget build(BuildContext context) {
    final width = collapsed
        ? DesignChrome.railWidthCollapsed
        : DesignChrome.railWidthExpanded;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: DesignTokens.railBg,
        border: Border(
          right: BorderSide(color: DesignTokens.railLine),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final item in items) ..._buildEntry(item),
              ],
            ),
          ),
          _Footer(version: footerVersion, collapsed: collapsed),
        ],
      ),
    );
  }

  List<Widget> _buildEntry(LobbySideRailItem item) {
    final widgets = <Widget>[];
    if (item.section != null && !collapsed) {
      widgets.add(_SectionHeader(label: item.section!));
    }
    widgets.add(
      _RailItem(
        item: item,
        active: item.id == selectedId,
        collapsed: collapsed,
        onTap: () => onSelect(item.id),
      ),
    );
    return widgets;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: DesignChrome.railItemPadX,
        right: DesignChrome.railItemPadX,
        top: 14,
        bottom: 6,
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.18 * 9.5,
          color: DesignTokens.lightInk3,
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final LobbySideRailItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? DesignTokens.railInk : DesignTokens.railInkDim;
    final bg =
        active ? DesignTokens.railHover : Colors.transparent;
    final accent = active ? DesignTokens.liveBase : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              left: BorderSide(color: accent, width: 2),
            ),
          ),
          padding: collapsed
              ? const EdgeInsets.symmetric(vertical: 10)
              : const EdgeInsets.symmetric(
                  horizontal: DesignChrome.railItemPadX - 2,
                  vertical: DesignChrome.railItemPadY,
                ),
          child: collapsed
              ? Center(child: Icon(item.icon, size: 16, color: fg))
              : Row(
                  children: [
                    Icon(item.icon, size: 16, color: fg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamilyUi,
                          fontSize: DesignTokens.fsTab,
                          color: fg,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      _Badge(count: item.badge!, active: active),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.active});
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active ? DesignTokens.liveBase : DesignTokens.railLine,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _format(count),
        style: TextStyle(
          fontFamily: DesignTokens.fontFamilyMono,
          fontSize: 10,
          color: active ? DesignTokens.liveInk : DesignTokens.railInkDim,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _format(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version, required this.collapsed});
  final String? version;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: collapsed
          ? const EdgeInsets.symmetric(vertical: 10)
          : const EdgeInsets.symmetric(
              horizontal: DesignChrome.railItemPadX,
              vertical: 10,
            ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: DesignTokens.railLine),
        ),
      ),
      child: collapsed
          ? const Icon(Icons.circle, size: 6, color: DesignTokens.railInkDim)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (version != null)
                  Text(
                    version!,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamilyMono,
                      fontSize: 10,
                      color: DesignTokens.lightInk3,
                    ),
                  ),
                const Icon(Icons.circle, size: 6, color: DesignTokens.railInkDim),
              ],
            ),
    );
  }
}
