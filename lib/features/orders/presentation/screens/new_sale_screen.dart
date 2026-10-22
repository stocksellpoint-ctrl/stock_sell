import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _CartLine {
  final ProductModel product;
  int quantity;
  String discountType;
  double discountValue;
  double? sellingPrice;

  _CartLine({
    required this.product,
    this.quantity = 1,
    this.discountType = 'none',
    this.discountValue = 0,
    this.sellingPrice,
  });

  double get finalUnitPrice => sellingPrice ?? 0.0;

  double get unitDiscount {
    if (discountType == 'percent') {
      return (finalUnitPrice * discountValue) / 100;
    } else if (discountType == 'amount') {
      return discountValue.clamp(0, finalUnitPrice);
    }
    return 0;
  }

  double get lineSubtotal => finalUnitPrice * quantity;
  double get lineDiscount => unitDiscount * quantity;
  double get lineTotal => lineSubtotal - lineDiscount;
  bool get hasDiscount => unitDiscount > 0;

  void setUnitPrice(double newPrice) {
    if (newPrice <= 0) {
      sellingPrice = null;
    } else {
      sellingPrice = newPrice;
    }
  }
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  CustomerModel? _selectedCustomer;
  final Map<String, _CartLine> _cart = {};
  bool _saving = false;

  String? _categoryFilter;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = context.read<InventoryProvider>();
      final cust = context.read<CustomerProvider>();
      final cat = context.read<CategoryProvider>();

      if (inv.products.isEmpty) inv.loadProducts();
      if (cust.customers.isEmpty) cust.loadCustomers();
      if (cat.categories.isEmpty) cat.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _cartItemCount =>
      _cart.values.fold<int>(0, (sum, l) => sum + l.quantity);

  double get _cartSubtotal =>
      _cart.values.fold<double>(0, (sum, l) => sum + l.lineSubtotal);

  double get _cartDiscount =>
      _cart.values.fold<double>(0, (sum, l) => sum + l.lineDiscount);

  double get _cartTotal => _cartSubtotal - _cartDiscount;

  void _addToCart(ProductModel product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id!]!.quantity += 1;
      } else {
        _cart[product.id!] = _CartLine(product: product);
      }
    });
  }

  void _decrementFromCart(String productId) {
    setState(() {
      final line = _cart[productId];
      if (line == null) return;
      if (line.quantity <= 1) {
        _cart.remove(productId);
      } else {
        line.quantity -= 1;
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() => _cart.remove(productId));
  }

  List<ProductModel> _filteredProducts(List<ProductModel> all) {
    var result = all;

    if (_categoryFilter != null) {
      result = result.where((p) => p.categoryId == _categoryFilter).toList();
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

  Future<void> _editLineDiscount(_CartLine line) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DiscountDialog(line: line),
    );

    if (result == null) return;

    setState(() {
      line.discountType = result['type'] as String;
      line.discountValue = (result['value'] as num).toDouble();
    });
  }

  /// Reloads products, customers, and categories; clears filters/search.
  Future<void> _reloadAll() async {
    final inv = context.read<InventoryProvider>();
    final cust = context.read<CustomerProvider>();
    final cat = context.read<CategoryProvider>();

    setState(() {
      _searchQuery = '';
      _categoryFilter = null;
    });
    _searchCtrl.clear();

    await Future.wait([
      inv.loadProducts(),
      cust.loadCustomers(),
      cat.loadCategories(),
    ]);

    if (!mounted) return;
    _snack('Page reloaded', success: true);
  }

  /// Shows the add-customer dialog. Returns true if a customer was created.
  Future<bool> _showAddCustomerDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddCustomerDialog(),
    );

    if (created != true || !mounted) return false;

    await context.read<CustomerProvider>().loadCustomers();
    if (!mounted) return false;

    final customers = context.read<CustomerProvider>().customers;
    if (customers.isNotEmpty) {
      setState(() {
        _selectedCustomer = customers.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );
      });
      _snack('Customer created and selected', success: true);
    }
    return true;
  }

  /// Opens the customer picker bottom sheet. Returns the selected customer,
  /// or null if the user dismissed without selecting.
  Future<CustomerModel?> _showCustomerPicker() async {
    final provider = context.read<CustomerProvider>();
    if (provider.customers.isEmpty) {
      await provider.loadCustomers();
      if (!mounted) return null;
    }

    final selected = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        customers: provider.customers,
        selectedId: _selectedCustomer?.id,
        onAddNew: _showAddCustomerDialog,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCustomer = selected);
    }
    return selected;
  }

  Future<bool> _submitForSheet() async {
    if (_selectedCustomer == null) {
      _snack('Please select a customer');
      return false;
    }
    if (_cart.isEmpty) {
      _snack('Add at least one product');
      return false;
    }

    for (final line in _cart.values) {
      if (line.finalUnitPrice <= 0) {
        _snack('Please enter a selling price for ${line.product.name}');
        return false;
      }
      if (line.quantity > line.product.quantity) {
        _snack(
          'Not enough stock for ${line.product.name} '
          '(have ${line.product.quantity}, need ${line.quantity})',
        );
        return false;
      }
    }

    setState(() => _saving = true);

    final items = _cart.values.map((line) {
      return OrderItemModel(
        productId: line.product.id!,
        productName: line.product.name,
        categoryId: line.product.categoryId,
        quantity: line.quantity,
        sellingPrice: line.finalUnitPrice,
        costPrice: line.product.costPrice,
        discountType: line.discountType,
        discountValue: line.discountValue,
      );
    }).toList();

    final order = OrderModel(
      customerId: _selectedCustomer!.id!,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      items: items,
      total: 0,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final ok = await context.read<OrderProvider>().createOrder(order);
    if (!mounted) return false;

    if (ok) {
      // Reset the page after a successful sale:
      //   - clear selected customer → back to "unselected" state
      //   - clear cart (it's already been saved as an order)
      setState(() {
        _saving = false;
        _selectedCustomer = null;
        _cart.clear();
      });

      await context.read<InventoryProvider>().loadProducts();
      if (!mounted) return false;

      _snack('Sale completed successfully', success: true);
      if (context.canPop()) context.pop();
      return true;
    } else {
      setState(() => _saving = false);
      final error = context.read<OrderProvider>().error ?? 'Save failed';
      _snack(error);
      return false;
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _showCartSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_saving,
      enableDrag: !_saving,
      builder: (_) => _CartSheet(
        cart: Map.from(_cart),
        customerName: _selectedCustomer?.name,
        hasCustomer: _selectedCustomer != null,
        onAdd: _addToCart,
        onRemove: _decrementFromCart,
        onDelete: _removeFromCart,
        onEditDiscount: _editLineDiscount,
        onComplete: _submitForSheet,
        onUpdatePrice: (line) {
          setState(() {});
        },
        onSelectCustomer: _showCustomerPicker,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomerProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final products = inventory.products;
    final filtered = _filteredProducts(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _reloadAll,
          ),
        ],
      ),

      body: Column(
        children: [
          _topRow(customers.customers),
          _categoryChips(categories),
          _resultCount(products.length, filtered.length),
          Expanded(
            child: products.isEmpty
                ? const EmptyView(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products available',
                    subtitle: 'Add products before creating a sale.',
                  )
                : filtered.isEmpty
                ? EmptyView(
                    icon: Icons.search_off,
                    title: 'No matching products',
                    subtitle: 'Try a different search or category.',
                    action: TextButton.icon(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _categoryFilter = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear filters'),
                    ),
                  )
                : _productsSection(filtered),
          ),
        ],
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCartSheet,
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                '$_cartItemCount  •  ${Formatters.currency(_cartTotal)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _topRow(List<CustomerModel> customers) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              value: _selectedCustomer?.id,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Customer',
                prefixIcon: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const IgnorePointer(
                      child: Icon(Icons.person_outline, size: 20),
                    ),
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: IgnorePointer(
                        child: CircleAvatar(
                          radius: 6,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.add, size: 8, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showAddCustomerDialog,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ],
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              items: customers
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  _selectedCustomer = customers.firstWhere((c) => c.id == id);
                });
              },
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            flex: 5,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                // ★ Marquee hint: scrolls only if the text doesn't fit
                hint: MarqueeHint(
                  text: 'Search product / SKU',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                hintMaxLines: 1,
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  // ← smaller reserve
                  minWidth: 28,
                  minHeight: 28,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips(List<CategoryModel> categories) {
    final chips = categories.where((c) => c.isParent).toList();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _categoryFilter == null,
              onSelected: (_) => setState(() => _categoryFilter = null),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: _categoryFilter == null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _categoryFilter == null
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: _categoryFilter == null
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            const SizedBox(width: 8),
            ...chips.map((c) {
              final selected = _categoryFilter == c.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _categoryFilter = selected ? null : c.id),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _resultCount(int total, int filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 4),
      color: AppColors.bg,
      child: Text(
        filtered == total
            ? '$total product${total == 1 ? '' : 's'}'
            : 'Showing $filtered of $total products',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _productsSection(List<ProductModel> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.lg),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (_, i) {
        final product = products[i];
        final line = _cart[product.id];
        final inCart = line?.quantity ?? 0;

        return _ProductRow(
          product: product,
          inCart: inCart,
          onAdd: () => _addToCart(product),
          onRemove: () => _decrementFromCart(product.id!),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Auto-marquee hint (only scrolls when text doesn't fit)
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// Auto-marquee hint (only scrolls when text doesn't fit).
// Scrolls INSIDE the given width — never leaks outside.
// ═══════════════════════════════════════════════════════════════

class MarqueeHint extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // pixels per second while scrolling

  const MarqueeHint({
    super.key,
    required this.text,
    this.style,
    this.velocity = 30,
  });

  @override
  State<MarqueeHint> createState() => _MarqueeHintState();
}

class _MarqueeHintState extends State<MarqueeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _measured = false;
  bool _overflowing = false;
  double _textWidth = 0;

  static const double _gap = 24; // gap between loop iterations

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _overflowing) _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measureOnce(double availableWidth) {
    if (_measured) return;
    _measured = true;

    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    _textWidth = tp.width;
    _overflowing = _textWidth > availableWidth;

    if (_overflowing) {
      final totalDistance = _textWidth + _gap;
      final seconds = totalDistance / widget.velocity;
      _controller.duration = Duration(milliseconds: (seconds * 1000).round());
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const TextStyle();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Post-frame measurement so first frame has a stable width.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measureOnce(constraints.maxWidth);
        });

        // Constrain to the field's width — this is the key bit that
        // stops the hint from leaking outside the TextField.
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: ClipRect(
            child: _overflowing
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final dx = -(_textWidth + _gap) * _controller.value;
                      return OverflowBox(
                        // Allow the translated text to move freely inside
                        // the ClipRect without being clamped.
                        alignment: Alignment.centerLeft,
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: Transform.translate(
                          offset: Offset(dx, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.text,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: style,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                // Fits → plain static text, no ticker running
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: style,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Add Customer dialog (owns its own controllers)
// ═══════════════════════════════════════════════════════════════

class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog();

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final customer = CustomerModel(
      id: '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final provider = context.read<CustomerProvider>();
    final ok = await provider.addCustomer(customer);

    if (!mounted) return;

    setState(() => _saving = false);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('New Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
                      Text('Creating...'),
                    ],
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Cart sheet
// ═══════════════════════════════════════════════════════════════

class _CartSheet extends StatefulWidget {
  final Map<String, _CartLine> cart;
  final String? customerName;
  final bool hasCustomer;
  final void Function(ProductModel) onAdd;
  final void Function(String) onRemove;
  final void Function(String) onDelete;
  final Future<void> Function(_CartLine) onEditDiscount;
  final Future<bool> Function() onComplete;
  final void Function(_CartLine) onUpdatePrice;
  final Future<CustomerModel?> Function() onSelectCustomer;

  const _CartSheet({
    required this.cart,
    required this.customerName,
    required this.hasCustomer,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
    required this.onEditDiscount,
    required this.onComplete,
    required this.onUpdatePrice,
    required this.onSelectCustomer,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  bool _submitting = false;
  late Map<String, _CartLine> _cart;

  String? _localCustomerName;
  bool _localHasCustomer = false;

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.cart);
    _localCustomerName = widget.customerName;
    _localHasCustomer = widget.hasCustomer;
  }

  double get _subtotal =>
      _cart.values.fold<double>(0, (s, l) => s + l.lineSubtotal);
  double get _discount =>
      _cart.values.fold<double>(0, (s, l) => s + l.lineDiscount);
  double get _total => _subtotal - _discount;

  void _add(ProductModel p) {
    setState(() {
      if (_cart.containsKey(p.id)) {
        _cart[p.id!]!.quantity += 1;
      } else {
        _cart[p.id!] = _CartLine(product: p);
      }
    });
    widget.onAdd(p);
  }

  void _remove(ProductModel p) {
    setState(() {
      final line = _cart[p.id!];
      if (line == null) return;
      if (line.quantity <= 1) {
        _cart.remove(p.id!);
      } else {
        line.quantity -= 1;
      }
    });
    widget.onRemove(p.id!);
  }

  void _delete(ProductModel p) {
    setState(() => _cart.remove(p.id!));
    widget.onDelete(p.id!);
  }

  Future<void> _editDiscount(_CartLine line) async {
    await widget.onEditDiscount(line);
    if (!mounted) return;
    setState(() {});
  }

  void _updatePrice(_CartLine line, String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        line.setUnitPrice(parsed);
      });
      widget.onUpdatePrice(line);
    }
  }

  Future<void> _pickCustomer() async {
    final selected = await widget.onSelectCustomer();
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _localCustomerName = selected.name;
        _localHasCustomer = true;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onComplete();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _cart.values.toList();

    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _localHasCustomer
                            ? InkWell(
                                onTap: _pickCustomer,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _localCustomerName ?? 'Customer',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: _pickCustomer,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_add_alt_1,
                                        size: 16,
                                        color: AppColors.danger,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Select customer',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              Flexible(
                child: lines.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Cart is empty'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: lines.length,
                        itemBuilder: (_, i) {
                          final line = lines[i];
                          return _CartItemRow(
                            line: line,
                            onAdd: () => _add(line.product),
                            onRemove: () => _remove(line.product),
                            onDelete: () => _delete(line.product),
                            onEditDiscount: () => _editDiscount(line),
                            onUpdatePrice: (val) => _updatePrice(line, val),
                          );
                        },
                      ),
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        Text(
                          Formatters.currency(_subtotal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    if (_discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Total Discount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '- ${Formatters.currency(_discount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Formatters.currency(_total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting || _cart.isEmpty
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.success.withValues(
                            alpha: 0.6,
                          ),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Completing Sale...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Complete Sale',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Customer picker sheet (Material-backed, ListTile-safe)
// ═══════════════════════════════════════════════════════════════

class _CustomerPickerSheet extends StatefulWidget {
  final List<CustomerModel> customers;
  final String? selectedId;
  final Future<bool> Function() onAddNew;

  const _CustomerPickerSheet({
    required this.customers,
    required this.selectedId,
    required this.onAddNew,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerModel> get _filtered {
    if (_query.isEmpty) return widget.customers;
    final q = _query.toLowerCase();
    return widget.customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Select Customer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await widget.onAddNew();
                        if (!context.mounted) return;
                        setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: _filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No customers found'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          final selected = c.id == widget.selectedId;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                child: Text(
                                  c.name.isNotEmpty
                                      ? c.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                c.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(context, c),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Cart item row
// ═══════════════════════════════════════════════════════════════

class _CartItemRow extends StatefulWidget {
  final _CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;
  final VoidCallback onEditDiscount;
  final void Function(String) onUpdatePrice;

  const _CartItemRow({
    required this.line,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
    required this.onEditDiscount,
    required this.onUpdatePrice,
  });

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late TextEditingController _priceCtrl;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _priceCtrl = TextEditingController(
      text: widget.line.finalUnitPrice.toStringAsFixed(2),
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _priceCtrl.text = widget.line.finalUnitPrice.toStringAsFixed(2);
        });
      } else {
        _priceCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _priceCtrl.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.finalUnitPrice != widget.line.finalUnitPrice) {
      _priceCtrl.text = widget.line.finalUnitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.line.product;
    final line = widget.line;
    final needsPrice = line.finalUnitPrice <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 4),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (p.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Image.network(
                    p.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _icon(),
                  ),
                )
              else
                _icon(),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconBtn(Icons.remove, widget.onRemove, enabled: true),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${line.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _iconBtn(
                      Icons.add,
                      widget.onAdd,
                      enabled: line.quantity < p.quantity,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  iconSize: 18,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: widget.onDelete,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Row(
              children: [
                Row(
                  children: [
                    const Text(
                      'AED ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 28,
                      child: TextField(
                        controller: _priceCtrl,
                        focusNode: _focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: needsPrice
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: needsPrice
                                  ? AppColors.danger
                                  : AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: needsPrice
                                  ? AppColors.danger
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            widget.onUpdatePrice(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  ' × ${line.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.currency(line.lineSubtotal),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: InkWell(
              onTap: widget.onEditDiscount,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      line.hasDiscount
                          ? Icons.local_offer
                          : Icons.local_offer_outlined,
                      size: 16,
                      color: line.hasDiscount
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      line.hasDiscount ? _discountLabel(line) : 'Add discount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: line.hasDiscount
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: line.hasDiscount
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (line.hasDiscount)
                      Text(
                        '- ${Formatters.currency(line.lineDiscount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Row(
              children: [
                const Text(
                  'Line total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.currency(line.lineTotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _discountLabel(_CartLine line) {
    if (line.discountType == 'percent') {
      return 'Discount ${line.discountValue.toStringAsFixed(0)}% '
          '(${Formatters.currency(line.unitDiscount)}/unit)';
    }
    return 'Discount ${Formatters.currency(line.unitDiscount)}/unit';
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        iconSize: 18,
        icon: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textLight,
        ),
        onPressed: enabled ? onTap : null,
      ),
    );
  }

  Widget _icon() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: const Icon(
      Icons.inventory_2_outlined,
      color: AppColors.primary,
      size: 20,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Product row
// ═══════════════════════════════════════════════════════════════

class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final int inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductRow({
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.quantity <= 0;
    final low = product.isLowStock;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: inCart > 0 ? AppColors.primary : AppColors.border,
          width: inCart > 0 ? 1.5 : 1,
        ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.currency(product.costPrice),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  outOfStock ? 'Out of stock' : 'In stock: ${product.quantity}',
                  style: TextStyle(
                    fontSize: 11,
                    color: outOfStock || low
                        ? AppColors.danger
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 132, child: _controls(outOfStock)),
        ],
      ),
    );
  }

  Widget _controls(bool outOfStock) {
    if (outOfStock) {
      return const Center(
        child: Text(
          '—',
          style: TextStyle(color: AppColors.textLight, fontSize: 18),
        ),
      );
    }

    if (inCart == 0) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: onAdd,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            iconSize: 22,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$inCart',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            iconSize: 22,
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: inCart >= product.quantity ? null : onAdd,
          ),
        ),
      ],
    );
  }

  Widget _icon() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
  );
}

// ═══════════════════════════════════════════════════════════════
// Discount dialog
// ═══════════════════════════════════════════════════════════════

class _DiscountDialog extends StatefulWidget {
  final _CartLine line;

  const _DiscountDialog({required this.line});

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late String _type;
  late TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _type = widget.line.discountType;
    _valueCtrl = TextEditingController(
      text: widget.line.discountValue == 0
          ? ''
          : widget.line.discountValue.toString(),
    );
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Discount for ${widget.line.product.name}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'none', label: Text('None')),
                ButtonSegment(value: 'amount', label: Text('AED')),
                ButtonSegment(value: 'percent', label: Text('%')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type != 'none') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _type == 'percent'
                      ? 'Discount (%)'
                      : 'Discount per unit (AED)',
                  helperText: _type == 'percent'
                      ? 'Applied to each unit'
                      : 'Deducted from each unit price',
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final v = double.tryParse(_valueCtrl.text.trim()) ?? 0;
            Navigator.pop(context, {'type': _type, 'value': v});
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
