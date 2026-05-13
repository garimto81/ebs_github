// EBS Lobby — mockup-style shell (top-bar + body).
//
// 2026-05-12 cycle 11 — 사용자 비판 후 mockup HTML 정합 재설계.
// 이전: TopBar + SideRail (rich navigation). 변경: dark mockup top-bar 만.
// SSOT: docs/mockups/ebs-lobby-{01,02,03,04}-*.html 모두 sidebar 없음.
//
// 2026-05-13 cycle 21 W3 — Reports 탭 폐기 + Hand History 독립 격상.
// SSOT: Players_HandHistory_API.md §8 Reports 폐기 영향.
//
// Sub-feature (Settings / Graphic Editor / Staff / Players / Hand History)
// 접근은 admin user menu popup (top-bar 우측) 으로 이전.
// 데이터 흐름 (Series → Event → Flight → Table) 은 PR #377 그대로 유지.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/theme/lobby_mockup_tokens.dart';
import '../../auth/auth_provider.dart';
import '../providers/cc_session_provider.dart';

class LobbyShell extends ConsumerWidget {
  const LobbyShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LobbyMockupTokens.bg,
      body: Column(
        children: [
          const _MockupTopBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Mockup 정합 top bar — `.hdr` 의 정확한 재현.
///
/// Layout: `[EBS LOBBY label]  spacer  [Active CC pill] [Admin: <name> ▼]`
/// All dimensions, colors, font sizes from mockup CSS.
class _MockupTopBar extends ConsumerWidget {
  const _MockupTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final userName = user?.displayName ?? 'Guest';
    final userRole = user?.role ?? 'viewer';
    final ccCount = ref.watch(activeCcCountProvider);

    return Container(
      height: 32, // mockup: padding 6px + ~20px content
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: LobbyMockupTokens.headerBg,
      child: Row(
        children: [
          // ── EBS LOBBY label (left) — click → /lobby/series ──
          GestureDetector(
            onTap: () => context.go('/lobby/series'),
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                'EBS LOBBY',
                style: TextStyle(
                  color: LobbyMockupTokens.headerInk,
                  fontSize: LobbyMockupTokens.fsHeaderLogo,
                  fontWeight: FontWeight.w700,
                  letterSpacing: LobbyMockupTokens.letterSpacingHeader,
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Active CC pill ──
          _CcPill(count: ccCount),

          const SizedBox(width: 12),

          // ── User menu popup (Admin: J.Kim) ──
          _UserMenu(name: userName, role: userRole),
        ],
      ),
    );
  }
}

/// Mockup `.cc-btn` — Active CC pill with green dot.
class _CcPill extends StatelessWidget {
  const _CcPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      color: LobbyMockupTokens.headerCcBg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Active CC',
            style: TextStyle(
              color: LobbyMockupTokens.headerInk,
              fontSize: LobbyMockupTokens.fsXs,
              fontWeight: FontWeight.w700,
              letterSpacing: LobbyMockupTokens.letterSpacingBtn,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: LobbyMockupTokens.ccLive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: LobbyMockupTokens.headerInk,
              fontSize: LobbyMockupTokens.fsXs,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup `.hdr-user` — 'Admin: J.Kim' + popup menu (sub-feature 접근).
class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleLabel = role.isEmpty
        ? '—'
        : '${role[0].toUpperCase()}${role.substring(1)}';
    final label = '$roleLabel: $name';
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      color: LobbyMockupTokens.bg,
      offset: const Offset(0, 28),
      onSelected: (v) => _onSelect(context, ref, v),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'players', child: Text('Players')),
        PopupMenuItem(value: 'hand-history', child: Text('Hand History')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuItem(value: 'gfx', child: Text('Graphic Editor')),
        PopupMenuItem(value: 'staff', child: Text('Staff')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LobbyMockupTokens.headerUserInk,
              fontSize: LobbyMockupTokens.fsXs,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_drop_down,
            size: 14,
            color: LobbyMockupTokens.headerUserInk,
          ),
        ],
      ),
    );
  }

  void _onSelect(BuildContext context, WidgetRef ref, String v) {
    switch (v) {
      case 'players':
        context.go('/players');
      case 'hand-history':
        context.go('/hand-history');
      case 'settings':
        context.go('/settings');
      case 'gfx':
        context.go('/graphic-editor');
      case 'staff':
        context.go('/staff');
      case 'logout':
        ref.read(authProvider.notifier).logout();
    }
  }
}
