


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  final String? filter;
  const InventoryScreen({super.key, this.filter});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedParentId;
  String? _selectedSubId;

  /// Tracks WHICH product is currently being deleted.
  /// Only that product's card shows the loading spinner.
  String? _deletingProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
      final catProvider = context.read<CategoryProvider>();
      if (catProvider.categories.isEmpty) {
        catProvider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> allProducts) {
    var result = allProducts;
    if (widget.filter == 'lowStock') {
      result = result.where((p) => p.isLowStock).toList();
    }

    if (_selectedSubId != null) {
      result = result.where((p) => p.categoryId == _selectedSubId).toList();
    } else if (_selectedParentId != null) {
      result = result.where((p) => p.categoryId == _selectedParentId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> _handleDelete(ProductModel product) async {
    // Only one delete at a time
    if (_deletingProductId != null) return;

    final provider = context.read<InventoryProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\n'
          'This will remove it from inventory. Past orders will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mark ONLY this product as deleting → only its card shows loading
    setState(() => _deletingProductId = product.id);

    final ok = await provider.deleteProduct(product.id!);

    if (!mounted) return;

    setState(() => _deletingProductId = null);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final catProvider = context.watch<CategoryProvider>();

    final allProducts = provider.products;
    final filtered = _getFilteredProducts(allProducts);

    final title = widget.filter == 'lowStock' ? 'Low Stock Items' : 'Product List';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
            tooltip: 'Add Product',
            onPressed: () => context.push('/inventory/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadProducts(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(catProvider),
          _buildSubCategoryChips(catProvider),
          _buildResultCount(allProducts.length, filtered.length),
          Expanded(child: _buildBody(provider, filtered)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
      color: AppColors.surface,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or SKU...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(CategoryProvider catProvider) {
    final parents = catProvider.categories.where((c) => c.isParent).toList();
    if (parents.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _selectedParentId == null && _selectedSubId == null,
              onSelected: (_) => setState(() {
                _selectedParentId = null;
                _selectedSubId = null;
              }),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: (_selectedParentId == null && _selectedSubId == null) ? FontWeight.bold : FontWeight.normal,
                color: (_selectedParentId == null && _selectedSubId == null) ? Colors.white : AppColors.textPrimary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(color: (_selectedParentId == null && _selectedSubId == null) ? AppColors.primary : AppColors.border),
            ),
            const SizedBox(width: 8),
            ...parents.map((c) {
              final isSelected = _selectedParentId == c.id || _selectedSubId == c.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    if (isSelected) {
                      _selectedParentId = null;
                      _selectedSubId = null;
                    } else {
                      _selectedParentId = c.id;
                      _selectedSubId = null;
                    }
                  }),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryChips(CategoryProvider catProvider) {
    if (_selectedParentId == null) return const SizedBox.shrink();

    final subs = catProvider.childrenOf(_selectedParentId!);
    if (subs.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: subs.map((c) {
            final isSelected = _selectedSubId == c.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedSubId = isSelected ? null : c.id;
                }),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.bg,
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultCount(int total, int filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 4),
      color: AppColors.bg,
      child: Text(
        filtered == total ? '$total product${total == 1 ? '' : 's'}' : 'Showing $filtered of $total products',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildBody(InventoryProvider provider, List<ProductModel> products) {
    if (provider.isLoading && provider.products.isEmpty) {
      return const LoadingIndicator(message: 'Loading products...');
    }

    if (provider.error != null && provider.products.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadProducts(),
      );
    }

    if (products.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'No products found',
        subtitle: 'Try a different search or category.',
        action: TextButton.icon(
          onPressed: () {
            _searchCtrl.clear();
            setState(() {
              _searchQuery = '';
              _selectedParentId = null;
              _selectedSubId = null;
            });
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear filters'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadProducts(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) {
          final product = products[i];
          return _ProductCard(
            product: product,
            // Only the product being deleted shows the loading state
            isDeleting: _deletingProductId == product.id,
            onTap: () => context.push('/inventory/${product.id}'),
            onDelete: () => _handleDelete(product),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _thumbnail(low),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.sku} • ${_categoryLabel()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(product.costPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${product.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: low ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: isDeleting ? null : onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isDeleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.danger,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: AppColors.danger,
                              ),
                        const SizedBox(width: 4),
                        Text(
                          isDeleting ? 'Deleting...' : 'Delete',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(bool low) {
    if (product.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.network(
          product.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconThumbnail(low),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _iconThumbnail(low);
          },
        ),
      );
    }
    return _iconThumbnail(low);
  }

  Widget _iconThumbnail(bool low) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: low ? AppColors.dangerLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: low ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _categoryLabel() {
    if (product.category != null) {
      return product.category!.name;
    }
    return 'Uncategorized';
  }
}