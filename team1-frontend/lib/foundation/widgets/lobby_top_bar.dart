// EBS Lobby — TopBar (44px brand + cluster + Active CC pill + clock + user).
//
// Mirrors `.topbar` in the design source (`.scratch/design-fetch/project/styles.css`)
// and the JSX in `shell.jsx`.
//
// Layout:
//   [brand · 240px] [cluster · 1fr · mono labels] [CC pill] [clock] [user]
//
// The brand cell collapses to 56px when the rail is in collapsed mode (driven
// by [collapsed]). The cluster is a row of (label, value) pairs with vertical
// dividers — by default it shows SHOW · FLIGHT · LEVEL · NEXT but the labels
// are caller-supplied via [clusters] so other screens (or empty states) can
// change them.

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'lobby_chrome_widgets.dart';

class LobbyTopBarCluster {
  const LobbyTopBarCluster(this.label, this.value);
  final String label;
  final String value;
}

class LobbyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LobbyTopBar({
    super.key,
    this.brand = 'EBS LOBBY',
    this.brandMark = 'E',
    this.collapsed = false,
    this.clusters = const [],
    this.activeCcCount,
    this.clock,
    this.userInitials,
    this.userLabel,
    this.onBrandTap,
  });

  final String brand;
  final String brandMark;
  final bool collapsed;
  final List<LobbyTopBarCluster> clusters;

  /// `null` hides the CC pill. Otherwise renders `Active CC · N` with the
  /// pulsing live dot when `> 0`.
  final int? activeCcCount;

  /// Optional clock string — caller manages the `Timer.periodic` updates.
  final String? clock;

  final String? userInitials;
  final String? userLabel;

  final VoidCallback? onBrandTap;

  @override
  Size get preferredSize => const Size.fromHeight(DesignChrome.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesignChrome.topBarHeight,
      decoration: const BoxDecoration(
        color: DesignTokens.railBg,
        border: Border(
          bottom: BorderSide(color: DesignTokens.railLine),
        ),
      ),
      child: Row(
        children: [
          _Brand(
            collapsed: collapsed,
            mark: brandMark,
            label: brand,
            onTap: onBrandTap,
          ),
          if (clusters.isNotEmpty) _Cluster(items: clusters),
          const Spacer(),
          if (activeCcCount != null) ...[
            _CcPill(count: activeCcCount!),
            const SizedBox(width: 12),
          ],
          if (clock != null) ...[
            Text(
              clock!,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamilyMono,
                fontSize: 11,
                color: DesignTokens.railInkDim,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (userLabel != null) _UserPill(initials: userInitials ?? '?', label: userLabel!),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.collapsed,
    required this.mark,
    required this.label,
    required this.onTap,
  });

  final bool collapsed;
  final String mark;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = collapsed
        ? DesignChrome.railWidthCollapsed
        : DesignChrome.railWidthExpanded;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: collapsed ? null : const EdgeInsets.symmetric(horizontal: 16),
        alignment: collapsed ? Alignment.center : null,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: DesignTokens.railLine),
          ),
        ),
        child: collapsed
            ? const _BrandMark(mark: 'E')
            : Row(
                children: [
                  _BrandMark(mark: mark),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamilyUi,
                      color: DesignTokens.railInk,
                      fontSize: DesignTokens.fsTab,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.14 * DesignTokens.fsTab,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.mark});
  final String mark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: DesignTokens.railInk,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: const TextStyle(
          color: DesignTokens.railBg,
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Cluster extends StatelessWidget {
  const _Cluster({required this.items});
  final List<LobbyTopBarCluster> items;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            height: 16,
            color: DesignTokens.railLine,
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),
        );
      }
      children.add(_ClusterPair(item: items[i]));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _ClusterPair extends StatelessWidget {
  const _ClusterPair({required this.item});
  final LobbyTopBarCluster item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyMono,
            fontSize: 10,
            color: DesignTokens.railInkDim,
            letterSpacing: 0.08 * 10,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          item.value,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyMono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DesignTokens.railInk,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CcPill extends StatelessWidget {
  const _CcPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.railLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) const PulsingLiveDot(size: 7) else const _IdleDot(),
          const SizedBox(width: 8),
          Text(
            'Active CC · $count',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesignTokens.railInk,
              letterSpacing: 0.04 * 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleDot extends StatelessWidget {
  const _IdleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: DesignTokens.railInkDim,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  const _UserPill({required this.initials, required this.label});
  final String initials;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: DesignTokens.railInk,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesignTokens.railBg,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyUi,
            fontSize: 11,
            color: DesignTokens.railInk,
          ),
        ),
      ],
    );
  }
}
