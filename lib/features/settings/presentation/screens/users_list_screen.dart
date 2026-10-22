import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().load();
    });
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This will permanently delete ${user.name} (${user.email}). '
          'Their products, orders, and customers will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.delete(user.id);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'User deleted' : (provider.error ?? 'Failed to delete'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _toggleActive(UserModel user) async {
    final provider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.toggleActive(user.id, !user.isActive);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (user.isActive ? 'User deactivated' : 'User activated')
              : (provider.error ?? 'Failed to update'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final me = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: provider.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/users/add'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
      ),
      body: _buildBody(provider, me),
    );
  }

  Widget _buildBody(UserProvider provider, UserModel? me) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.users.isEmpty) {
      return const EmptyView(
        icon: Icons.people_outline,
        title: 'No users yet',
        subtitle: 'Add your first manager.',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          96,
        ),
        itemCount: provider.users.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) {
          final u = provider.users[i];
          final isMe = u.id == me?.id;
          final isPending = provider.deletingId == u.id;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: u.isAdmin
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.info.withValues(alpha: 0.15),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: u.isAdmin ? AppColors.primary : AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (isMe) _badge('YOU', AppColors.primary),
                          _badge(
                            u.role.toUpperCase(),
                            u.isAdmin ? AppColors.primary : AppColors.info,
                          ),
                          if (!u.isActive) _badge('INACTIVE', AppColors.danger),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isPending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        context.push('/settings/users/edit/${u.id}');
                      } else if (v == 'toggle') {
                        await _toggleActive(u);
                      } else if (v == 'delete' && !isMe) {
                        await _confirmDelete(u);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            u.isActive
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                          ),
                          title: Text(u.isActive ? 'Deactivate' : 'Activate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (!isMe)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.danger),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
