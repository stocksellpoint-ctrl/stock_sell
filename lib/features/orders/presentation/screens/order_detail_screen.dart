


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../data/models/order_model.dart';
import '../../services/invoice_generator.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final matches = provider.orders.where((o) => o.id == widget.orderId).toList();

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = matches.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id?.substring(0, 8) ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Preview Invoice',
            onPressed: () => _generateInvoice(context, order),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Invoice',
            onPressed: () => _shareInvoice(context, order),
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: 'Delete Order',
            onPressed: _isDeleting ? null : () => _confirmDelete(context, order),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _customerCard(order),
            const SizedBox(height: AppSizes.md),
            _statusCard(context, provider, order),
            const SizedBox(height: AppSizes.md),
            _itemsCard(order),
            const SizedBox(height: AppSizes.md),
            _totalCard(order),
            const SizedBox(height: AppSizes.xl),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateInvoice(context, order),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareInvoice(context, order),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, OrderModel order) async {
    if (_isDeleting) return;

    final provider = context.read<OrderProvider>();
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text(
          'Order #${order.id?.substring(0, 8) ?? ''} '
          'for ${order.customerName}. This cannot be undone.',
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

    setState(() => _isDeleting = true);

    // Show non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeletingDialog(message: 'Deleting order...'),
    );

    final ok = await provider.deleteOrder(order.id!);

    if (!context.mounted) return;

    // Dismiss the loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _isDeleting = false);

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      router.go('/orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete order'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _generateInvoice(BuildContext context, OrderModel order) async {
    try {
      final customer = _lookupCustomer(context, order);
      final bytes = await InvoiceGenerator.build(
        order: order,
        customer: customer,
        businessName: 'DAR AL MURUZ',
        businessAddress: 'Used Auto Parts & Accessories',
        businessPhone: '0569691508',
      );
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Invoice-${order.id?.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open invoice: $e')),
      );
    }
  }

  Future<void> _shareInvoice(BuildContext context, OrderModel order) async {
    try {
      final customer = _lookupCustomer(context, order);
      final bytes = await InvoiceGenerator.build(
        order: order,
        customer: customer,
        businessName: 'DAR AL MURUZ',
        businessAddress: 'Used Auto Parts & Accessories',
        businessPhone: '0569691508',
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoice_${order.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice for Order #${order.id?.substring(0, 8) ?? ''}',
        text: 'Hi ${order.customerName}, please find your invoice attached.',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share invoice: $e')),
      );
    }
  }

  CustomerModel? _lookupCustomer(BuildContext context, OrderModel order) {
    try {
      final customers = context.read<CustomerProvider>().customers;
      final matches = customers.where((c) => c.id == order.customerId);
      return matches.isNotEmpty ? matches.first : null;
    } catch (_) {
      return null;
    }
  }

  Widget _customerCard(OrderModel order) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUSTOMER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          order.customerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (order.customerPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            order.customerPhone,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    ),
  );

  Widget _statusCard(BuildContext context, OrderProvider provider, OrderModel order) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        DropdownButton<String>(
          value: order.status,
          isExpanded: true,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'processing', child: Text('Processing')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (v) {
            if (v != null) provider.updateStatus(order.id!, v);
          },
        ),
      ],
    ),
  );

  Widget _itemsCard(OrderModel order) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ITEMS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.currency(item.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${Formatters.currency(item.sellingPrice)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    if (item.hasDiscount)
                      Text(
                        'Subtotal ${Formatters.currency(item.lineSubtotal)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
                if (item.hasDiscount) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 12, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Text(
                        item.discountType == 'percent'
                            ? 'Discount ${item.discountValue.toStringAsFixed(0)}% (${Formatters.currency(item.discountAmount)}/unit)'
                            : 'Discount ${Formatters.currency(item.discountAmount)}/unit',
                        style: const TextStyle(color: AppColors.danger, fontSize: 11),
                      ),
                      const Spacer(),
                      Text(
                        '- ${Formatters.currency(item.lineDiscount)}',
                        style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _totalCard(OrderModel order) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Text(Formatters.currency(order.total), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Reusable non-dismissible loading dialog
// ---------------------------------------------------------------------------
class _DeletingDialog extends StatelessWidget {
  final String message;
  const _DeletingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}