import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(
            currentPath: location,
            isAdmin: auth.isAdmin,
            username: auth.currentUser?.username ?? '',
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String emoji;
  final String label;
  final bool adminOnly;

  const _NavItem({
    required this.path,
    required this.emoji,
    required this.label,
    this.adminOnly = false,
  });
}

final _navItems = [
  const _NavItem(
    path: '/dashboard',
    emoji: '📊',
    label: 'Dashboard',
  ),
  const _NavItem(
    path: '/pos',
    emoji: '💻',
    label: 'POS Sale',
  ),
  const _NavItem(
    path: '/inventory',
    emoji: '📦',
    label: 'Products',
  ),
  const _NavItem(
    path: '/history',
    emoji: '📜',
    label: 'Summary',
  ),
  const _NavItem(
    path: '/users',
    emoji: '👥',
    label: 'Users',
    adminOnly: true,
  ),
];

class _Sidebar extends ConsumerWidget {
  final String currentPath;
  final bool isAdmin;
  final String username;

  const _Sidebar({
    required this.currentPath,
    required this.isAdmin,
    required this.username,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🖨️',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                 const SizedBox(width: 12),
                const BrandLogo(fontSize: 18),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _navItems
                  .where((item) => !item.adminOnly || isAdmin)
                  .map((item) {
                    final isActive = currentPath.startsWith(item.path);
                    return _NavTile(item: item, isActive: isActive);
                  })
                  .toList(),
            ),
          ),
          // User info & logout
          const Divider(height: 1, color: AppColors.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isAdmin ? 'Administrator' : 'Staff',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Text(
                    '🚪',
                    style: TextStyle(fontSize: 16),
                  ),
                  tooltip: 'Logout',
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTile({required this.item, required this.isActive});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.item.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : _hovered
                ? AppColors.surfaceVariant
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Text(
                widget.item.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isActive
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.isActive) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
