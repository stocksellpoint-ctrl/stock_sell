import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  /// Tracks WHICH customer is currently being deleted.
  /// Only that row shows the spinner.
  String? _deletingCustomerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  Future<void> _confirmDelete(String id, String name) async {
    // Only one delete at a time
    if (_deletingCustomerId != null) return;

    final provider = context.read<CustomerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          'This will permanently delete "$name". '
          'Past orders linked to this customer will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _deletingCustomerId = id);

    // Non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeletingCustomerDialog(),
    );

    final success = await provider.deleteCustomer(id);

    if (!mounted) return;

    // Dismiss the loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _deletingCustomerId = null);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Customer deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to delete customer'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'Add Customer',
            onPressed: () => context.push('${RouteNames.customers}/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadCustomers(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: provider.isLoading && provider.customers.isEmpty
          ? const LoadingIndicator(message: 'Loading customers...')
          : provider.customers.isEmpty
          ? const EmptyView(
              icon: Icons.people_outline,
              title: 'No customers yet',
              subtitle: 'Add your first customer to get started.',
            )
          : RefreshIndicator(
              onRefresh: () => provider.loadCustomers(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.lg),
                itemCount: provider.customers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.md),
                itemBuilder: (_, i) {
                  final c = provider.customers[i];
                  final isDeleting = _deletingCustomerId == c.id;

                  return ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${c.phone}\n${c.email}'),
                    isThreeLine: true,
                    trailing: isDeleting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push(
                                  '${RouteNames.customers}/edit/${c.id}',
                                );
                              } else if (value == 'delete') {
                                _confirmDelete(c.id!, c.name);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
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
                    onTap: isDeleting
                        ? null
                        : () => context.push(
                            '${RouteNames.customers}/edit/${c.id}',
                          ),
                  );
                },
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Loading dialog used while a customer is being deleted
// ═══════════════════════════════════════════════════════════════

class _DeletingCustomerDialog extends StatelessWidget {
  const _DeletingCustomerDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: const [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Deleting customer...',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
