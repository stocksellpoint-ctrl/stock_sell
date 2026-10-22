import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/models/category_model.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Tracks which parent IDs are currently expanded
  final Set<String> _expandedParents = {};

  /// Tracks WHICH category is currently being deleted.
  String? _deletingCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoryProvider>().loadCategories();
      if (!mounted) return;

      // Auto-expand parents that have children on first load
      final provider = context.read<CategoryProvider>();
      setState(() {
        for (final parent in provider.parents) {
          if (provider.childrenOf(parent.id).isNotEmpty) {
            _expandedParents.add(parent.id);
          }
        }
      });
    });
  }

  void _toggleParent(String parentId) {
    setState(() {
      if (_expandedParents.contains(parentId)) {
        _expandedParents.remove(parentId);
      } else {
        _expandedParents.add(parentId);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () => _showAddDialog(isSub: false),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => provider.loadCategories(),
          ),
        ],
      ),

      body: _buildBody(provider),
    );
  }

  Widget _buildBody(CategoryProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const LoadingIndicator(message: 'Loading categories...');
    }

    if (provider.categories.isEmpty) {
      return EmptyView(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        subtitle: 'Tap the button below to add one.',
        action: ElevatedButton.icon(
          onPressed: () => _showAddDialog(isSub: false),
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCategories(),
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          ...provider.parents.map((parent) {
            final children = provider.childrenOf(parent.id);
            final isExpanded = _expandedParents.contains(parent.id);

            return _CategorySection(
              parent: parent,
              children: children,
              isExpanded: isExpanded,
              isDeleting: _deletingCategoryId == parent.id,
              deletingChildId: _deletingCategoryId,
              onToggleExpand: () => _toggleParent(parent.id),
              onAddSub: () => _showAddDialog(isSub: true, parentId: parent.id),
              onEdit: () => _showEditDialog(parent),
              onDelete: () => _confirmDelete(parent),
              onEditChild: _showEditDialog,
              onDeleteChild: _confirmDelete,
            );
          }),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Add dialog (parent or sub) — with in-dialog loading state
  // ═══════════════════════════════════════════════════════════

  Future<void> _showAddDialog({required bool isSub, String? parentId}) async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // block tap-outside while creating
      builder: (dialogContext) {
        // Local state so the Create button can show a spinner
        return _AddEditCategoryDialog(
          title: isSub ? 'New Sub-Category' : 'New Category',
          confirmLabel: 'Create',
          onSubmit: (name, description) async {
            final category = CategoryModel(
              id: '',
              name: name,
              slug: '',
              description: description,
              parentId: parentId,
            );
            return provider.addCategory(category);
          },
          onDone: (ok) {
            Navigator.of(dialogContext).pop();
            if (!ok) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(provider.error ?? 'Failed to create'),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }
            // Expand the parent automatically so the new sub appears
            if (parentId != null && mounted) {
              setState(() => _expandedParents.add(parentId));
            }
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Category created'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Edit dialog — with in-dialog loading state
  // ═══════════════════════════════════════════════════════════

  Future<void> _showEditDialog(CategoryModel category) async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AddEditCategoryDialog(
          title: 'Edit Category',
          confirmLabel: 'Save',
          initialName: category.name,
          initialDescription: category.description ?? '',
          onSubmit: (name, description) async {
            final updated = category.copyWith(
              name: name,
              description: description,
            );
            return provider.updateCategory(updated);
          },
          onDone: (ok) {
            Navigator.of(dialogContext).pop();
            if (!ok) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(provider.error ?? 'Failed to update'),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Category updated'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Delete confirmation — with loading indicator
  // ═══════════════════════════════════════════════════════════

  Future<void> _confirmDelete(CategoryModel category) async {
    // Guard: only one delete at a time
    if (_deletingCategoryId != null) return;

    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'This will permanently delete "${category.name}". '
          'It will fail if products or sub-categories reference it.',
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

    setState(() => _deletingCategoryId = category.id);

    // Non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeletingCategoryDialog(),
    );

    final success = await provider.deleteCategory(category.id);

    if (!mounted) return;

    // Dismiss the loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _deletingCategoryId = null);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Category deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to delete'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable Add/Edit dialog with built-in loading state
// ═══════════════════════════════════════════════════════════════

class _AddEditCategoryDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final String initialDescription;
  final Future<bool> Function(String name, String? description) onSubmit;
  final void Function(bool ok) onDone;

  const _AddEditCategoryDialog({
    required this.title,
    required this.confirmLabel,
    required this.onSubmit,
    required this.onDone,
    this.initialName = '',
    this.initialDescription = '',
  });

  @override
  State<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<_AddEditCategoryDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final ok = await widget.onSubmit(name, desc);

    if (!mounted) return;

    setState(() => _saving = false);

    if (!mounted) return;

    widget.onDone(ok);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                : Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Loading dialog used while a category is being deleted
// ═══════════════════════════════════════════════════════════════

class _DeletingCategoryDialog extends StatelessWidget {
  const _DeletingCategoryDialog();

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
                'Deleting category...',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Category section (parent + collapsible children)
// ═══════════════════════════════════════════════════════════════

class _CategorySection extends StatelessWidget {
  final CategoryModel parent;
  final List<CategoryModel> children;
  final bool isExpanded;
  final bool isDeleting;
  final String? deletingChildId;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddSub;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(CategoryModel) onEditChild;
  final void Function(CategoryModel) onDeleteChild;

  const _CategorySection({
    required this.parent,
    required this.children,
    required this.isExpanded,
    required this.isDeleting,
    required this.deletingChildId,
    required this.onToggleExpand,
    required this.onAddSub,
    required this.onEdit,
    required this.onDelete,
    required this.onEditChild,
    required this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = children.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Parent header ────────────────────────────────
          InkWell(
            onTap: hasChildren ? onToggleExpand : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                parent.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasChildren) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${children.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (parent.description != null &&
                            parent.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            parent.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (hasChildren)
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ),

                  if (isDeleting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'add_sub':
                            onAddSub();
                            break;
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'add_sub',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.add),
                            title: Text('Add Sub-Category'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
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
                ],
              ),
            ),
          ),

          // ── Collapsible children ─────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded && hasChildren
                ? Column(
                    children: [
                      const Divider(height: 1),
                      ...children.map(
                        (child) => _SubCategoryRow(
                          child: child,
                          isDeleting: deletingChildId == child.id,
                          onEdit: () => onEditChild(child),
                          onDelete: () => onDeleteChild(child),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Empty state ──────────────────────────────────
          if (!hasChildren) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'No sub-categories',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onAddSub,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('+ Add'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-category row
// ═══════════════════════════════════════════════════════════════

class _SubCategoryRow extends StatelessWidget {
  final CategoryModel child;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubCategoryRow({
    required this.child,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Icon(
              Icons.subdirectory_arrow_right,
              color: AppColors.textLight,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (child.description != null && child.description!.isNotEmpty)
                  Text(
                    child.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          if (isDeleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
