import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_size.dart';
import '../../../core/utils/formatters.dart';
import '../../inventory/data/models/product_model.dart';
import '../../inventory/presentation/providers/inventory_provider.dart';

class StockValueScreen extends StatelessWidget {
  const StockValueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    if (provider.isLoading && provider.products.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ★ Changed to use costPrice for sorting
    final products = [...provider.products]
      ..sort(
        (a, b) =>
            (b.costPrice * b.quantity).compareTo(a.costPrice * a.quantity),
      );

    // ★ Changed to use costPrice for total
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + p.costPrice * p.quantity,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Value')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.xl),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Stock Value (Cost)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(totalValue),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${products.length} product(s)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (_, i) {
                final p = products[i];
                return _StockValueCard(product: p);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockValueCard extends StatelessWidget {
  final ProductModel product;
  const _StockValueCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // ★ Changed to use costPrice
    final lineTotal = product.costPrice * product.quantity;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (product.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Image.network(
                product.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _icon(),
              ),
            )
          else
            _icon(),
          const SizedBox(width: AppSizes.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  // ★ Changed to costPrice
                  '${product.quantity} × ${Formatters.currency(product.costPrice)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            Formatters.currency(lineTotal),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
    );
  }
}
