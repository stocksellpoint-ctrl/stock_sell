import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_sell/core/config/app_info.dart';
import 'package:stock_sell/core/constants/app_colors.dart';

import '../../../../core/services/update_service.dart';
import 'update_dialog.dart';

import 'package:stock_sell/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Reached via drawer (context.go) → no stack, go home
              context.go('/home');
            }
          },
        ),
      ),

      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Business information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _notImplemented(context),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/appearance'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/language'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/user'),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Manage users'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/users'),
            ),

          // ★ NEW: Check for updates
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('Check for updates'),
            subtitle: Text('Current version: ${AppInfo.version}'),
            trailing: const Icon(Icons.refresh),
            onTap: () => _checkForUpdates(context),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _notImplemented(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _notImplemented(context),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show a lightweight spinner while hitting the API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CheckingDialog(),
    );

    try {
      final update = await UpdateService.instance.checkForUpdate(
        currentVersion: AppInfo.version,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner

      if (update == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You are on the latest version'),
            backgroundColor: AppColors.success,
          ),
        );
        return;
      }

      // Prompt to install
      final install = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateAvailableDialog(update: update),
      );
      if (install != true || !context.mounted) return;

      // Download + install
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDownloadDialog(update: update),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Update check failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _CheckingDialog extends StatelessWidget {
  const _CheckingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 16),
          Expanded(child: Text('Checking for updates...')),
        ],
      ),
    );
  }
}
