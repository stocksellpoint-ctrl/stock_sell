import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_sell/core/config/app_info.dart';

import '../constants/app_colors.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header reaches the very top edge
          _buildHeader(context, scheme, isDark, user, auth),

          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      children: [
                        _sectionLabel('MAIN', scheme),
                        _item(
                          context,
                          icon: Icons.dashboard_outlined,
                          label: 'Dashboard',
                          path: '/home',
                        ),
                        _item(
                          context,
                          icon: Icons.inventory_2_outlined,
                          label: 'Inventory',
                          path: '/inventory',
                        ),
                        _item(
                          context,
                          icon: Icons.people_outline,
                          label: 'Customers',
                          path: '/customers',
                        ),
                        _item(
                          context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Sales',
                          path: '/orders',
                        ),
                        _item(
                          context,
                          icon: Icons.insights_outlined,
                          label: 'Reports',
                          path: '/reports',
                        ),
                        const SizedBox(height: 8),
                        _sectionLabel('PREFERENCES', scheme),

                        _item(
                          context,
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          path: '/settings',
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppInfo.appName} • v${AppInfo.version}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Developed by ${AppInfo.developerName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.35),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse(
                              'mailto:${AppInfo.developerEmail}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 11,
                                  color: scheme.primary.withValues(alpha: 0.65),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppInfo.developerEmail,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.primary.withValues(
                                      alpha: 0.65,
                                    ),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme scheme,
    bool isDark,
    dynamic user,
    AuthProvider auth,
  ) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, isDark ? 0.15 : 0.10)!,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topInset + 20, 8, 20),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              context.push('/settings/user');
            },
            customBorder: const CircleBorder(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: Text(
                  (user?.name?.isNotEmpty ?? false)
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/user');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, auth),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    // Capture everything we need BEFORE closing the drawer, so we don't
    // touch a deactivated context after the pop.
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);

    // Close the drawer first.
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // ★ Guard #1: user may have dismissed the app while the dialog was open
    if (confirmed != true || !navigator.mounted) return;

    // ── Non-dismissible loading dialog while logging out ──
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const _LoggingOutDialog(),
    );

    // Auth was captured before the pop; the drawer's context is gone but
    // the provider instance is still valid.

    try {
      await auth.logout();
    } catch (_) {}

    // ★ Guard #2: the async gap from auth.logout() could have unmounted us
    if (!navigator.mounted) return;

    // Dismiss the loading dialog.
    navigator.pop();

    // Navigate to login.
    router.go('/login');
  }

  Widget _sectionLabel(String text, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
  }) {
    final current = GoRouterState.of(context).matchedLocation;
    final isActive =
        current == path || (path != '/' && current.startsWith(path));

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? scheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        leading: Icon(
          icon,
          size: 22,
          color: isActive
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.75),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (current != path) context.go(path);
        },
      ),
    );
  }
}

/// Non-dismissible spinner shown while logging out.
class _LoggingOutDialog extends StatelessWidget {
  const _LoggingOutDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // block back button while logging out
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('Logging out...', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
