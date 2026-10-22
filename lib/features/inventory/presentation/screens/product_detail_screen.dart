import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import 'package:stock_sell/core/constants/app_size.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/inventory_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final matches = provider.products.where((p) => p.id == productId).toList();

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }
    final product = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('${RouteNames.inventory}/edit/${product.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _productImage(product),

            const SizedBox(height: AppSizes.lg),

            _row('Name', product.name),
            _row('SKU', product.sku),
            _row('Category', _categoryLabel(product)),

            // ★ Changed to Cost Price
            _row('Cost Price', Formatters.currency(product.costPrice)),

            _row('Quantity', '${product.quantity}'),
            _row('Low Stock Threshold', '${product.lowStockThreshold}'),
            _row(
              'Status',
              product.isLowStock ? 'Low Stock' : 'In Stock',
              valueColor: product.isLowStock
                  ? AppColors.danger
                  : AppColors.success,
            ),

            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              _row('Description', product.description!),
            ],

            const SizedBox(height: AppSizes.xl),

            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete product?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await provider.deleteProduct(product.id!);
                  if (context.mounted) context.pop();
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              label: const Text(
                'Delete Product',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productImage(dynamic product) {
    final hasImage = product.hasImage as bool;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Image.network(
                product.imageUrl as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              ),
            )
          : _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 72,
        color: AppColors.primary,
      ),
    );
  }

  String _categoryLabel(dynamic product) {
    final category = product.category;
    if (category != null) {
      return category.name as String;
    }
    final categoryId = product.categoryId;
    if (categoryId != null && (categoryId as String).isNotEmpty) {
      return 'ID: $categoryId';
    }
    return '—';
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
