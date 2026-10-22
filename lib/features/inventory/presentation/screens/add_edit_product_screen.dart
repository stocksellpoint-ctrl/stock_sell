import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/features/categories/presentation/providers/category_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../categories/data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../providers/inventory_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final _thresholdCtrl = TextEditingController(text: '10');

  final _picker = ImagePicker();

  File? _pickedImage;
  String? _existingImageUrl;

  String? _categoryId;
  String? _subCategoryId;

  bool _saving = false;
  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catProvider = context.read<CategoryProvider>();

      if (catProvider.categories.isEmpty) {
        await catProvider.loadCategories();
      }

      if (_isEditing) {
        _prefillFromExistingProduct(catProvider);
      }
    });
  }

  void _prefillFromExistingProduct(CategoryProvider catProvider) {
    final provider = context.read<InventoryProvider>();
    final matches = provider.products
        .where((x) => x.id == widget.productId)
        .toList();

    if (matches.isEmpty) return;
    final p = matches.first;

    _nameCtrl.text = p.name;
    _skuCtrl.text = p.sku;
    _costPriceCtrl.text = p.costPrice.toString();
    _qtyCtrl.text = p.quantity.toString();
    _descriptionCtrl.text = p.description ?? '';
    _existingImageUrl = p.imageUrl;

    _thresholdCtrl.text = p.lowStockThreshold.toString();

    final productCategory = catProvider.categories
        .where((c) => c.id == p.categoryId)
        .toList();

    if (productCategory.isNotEmpty) {
      final cat = productCategory.first;
      if (cat.parentId != null && cat.parentId!.isNotEmpty) {
        _categoryId = cat.parentId;
        _subCategoryId = cat.id;
      } else {
        _categoryId = cat.id;
        _subCategoryId = null;
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _costPriceCtrl.dispose();
    _qtyCtrl.dispose();
    _descriptionCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return;

      setState(() => _pickedImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_pickedImage != null || _existingImageUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Remove image',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _existingImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog({required bool isSub}) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryProvider = context.read<CategoryProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSub ? 'New Sub-Category' : 'New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final category = CategoryModel(
                id: '',
                name: name,
                slug: '',
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                parentId: isSub ? _categoryId : null,
              );

              final ok = await categoryProvider.addCategory(category);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (ok) {
                await categoryProvider.loadCategories();

                if (isSub && _categoryId != null) {
                  final subs = categoryProvider.childrenOf(_categoryId!);
                  if (subs.isNotEmpty) {
                    setState(() => _subCategoryId = subs.last.id);
                  }
                } else if (!isSub) {
                  final parents = categoryProvider.parents;
                  if (parents.isNotEmpty) {
                    setState(() => _categoryId = parents.last.id);
                  }
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      categoryProvider.error ?? 'Failed to create category',
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final finalCategoryId = _subCategoryId ?? _categoryId;
    if (finalCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<InventoryProvider>();
    final product = ProductModel(
      id: widget.productId,
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim().toUpperCase(),
      categoryId: finalCategoryId,
      costPrice: double.tryParse(_costPriceCtrl.text.trim()) ?? 0,
      quantity: int.parse(_qtyCtrl.text.trim()),
      lowStockThreshold: int.tryParse(_thresholdCtrl.text.trim()) ?? 10,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );

    final ok = _isEditing
        ? await provider.updateProduct(product, imagePath: _pickedImage?.path)
        : await provider.addProduct(product, imagePath: _pickedImage?.path);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error ?? 'Save failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final parents = categoryProvider.parents;
    final subs = _categoryId == null
        ? <CategoryModel>[]
        : categoryProvider.childrenOf(_categoryId!);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _imagePickerCard(),
              const SizedBox(height: AppSizes.lg),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: AppSizes.md),

              TextFormField(
                controller: _skuCtrl,
                decoration: const InputDecoration(labelText: 'SKU'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  // Optional: empty is fine.
                  if (v == null || v.trim().isEmpty) return null;

                  // If present, validate length.
                  if (v.trim().length < 2) return 'At least 2 characters';
                  if (v.trim().length > 40) return 'At most 40 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              _categoryDropdown(parents),
              const SizedBox(height: AppSizes.md),

              if (_categoryId != null && subs.isNotEmpty) ...[
                _subCategoryDropdown(subs),
                const SizedBox(height: AppSizes.md),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price (AED)',
                        helperText: 'What you paid for this item',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveNumber(v, field: 'Cost Price'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveNumber(v, field: 'Quantity'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              TextFormField(
                controller: _thresholdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  helperText: 'Warn when stock falls to or below this number',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    Validators.positiveNumber(v, field: 'Threshold'),
              ),
              const SizedBox(height: AppSizes.md),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),

              const SizedBox(height: AppSizes.xl),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown(List<CategoryModel> parents) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _categoryId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Category',
              hintText: parents.isEmpty ? 'No categories yet' : null,
            ),
            items: parents
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _categoryId = value;
                _subCategoryId = null;
              });
            },
            validator: (v) => v == null ? 'Category is required' : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Create new category',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showCreateCategoryDialog(isSub: false),
        ),
      ],
    );
  }

  Widget _subCategoryDropdown(List<CategoryModel> subs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _subCategoryId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sub-Category (optional)',
            ),
            items: subs
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              setState(() => _subCategoryId = value);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Create new sub-category',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showCreateCategoryDialog(isSub: true),
        ),
      ],
    );
  }

  Widget _imagePickerCard() {
    final hasNewImage = _pickedImage != null;
    final hasExisting =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: hasNewImage
            ? _imageWithEditOverlay(
                Image.file(_pickedImage!, fit: BoxFit.cover),
              )
            : hasExisting
            ? _imageWithEditOverlay(
                Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                ),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imageWithEditOverlay(Widget imageWidget) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: imageWidget,
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _showImageSourceSheet,
              icon: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to add product image',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gallery or camera',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
