// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/constants/app_size.dart';
// import '../../../../core/utils/validators.dart';
// import '../../data/models/customer_model.dart';
// import '../providers/customer_provider.dart';

// class AddEditCustomerScreen extends StatefulWidget {
//   final String? customerId;
//   const AddEditCustomerScreen({super.key, this.customerId});

//   @override
//   State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
// }

// class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _addressCtrl = TextEditingController();

//   bool _saving = false;
//   bool get _isEditing => widget.customerId != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditing) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final c = context.read<CustomerProvider>().customers.firstWhere(
//           (x) => x.id == widget.customerId,
//         );
//         _nameCtrl.text = c.name;
//         _phoneCtrl.text = c.phone;
//         _emailCtrl.text = c.email;
//         _addressCtrl.text = c.address ?? '';
//         setState(() {});
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _phoneCtrl.dispose();
//     _emailCtrl.dispose();
//     _addressCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _saving = true);

//     final provider = context.read<CustomerProvider>();
//     final customer = CustomerModel(
//       id: widget.customerId,
//       name: _nameCtrl.text.trim(),
//       phone: _phoneCtrl.text.trim(),
//       email: _emailCtrl.text.trim(),
//       address: _addressCtrl.text.trim(),
//       createdAt: DateTime.now(),
//     );

//     final ok = _isEditing
//         ? await provider.updateCustomer(customer)
//         : await provider.addCustomer(customer);

//     if (!mounted) return;
//     setState(() => _saving = false);
//     if (ok) context.pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(AppSizes.lg),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _nameCtrl,
//                 decoration: const InputDecoration(labelText: 'Name'),
//                 validator: (v) => Validators.required(v, field: 'Name'),
//               ),
//               const SizedBox(height: AppSizes.md),
//               TextFormField(
//                 controller: _phoneCtrl,
//                 decoration: const InputDecoration(labelText: 'Phone'),
//                 keyboardType: TextInputType.phone,
//                 validator: Validators.phone,
//               ),
//               const SizedBox(height: AppSizes.md),
//               TextFormField(
//                 controller: _emailCtrl,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return null;   // optional
//                   return Validators.email(v);                       // format check when provided
//                 },
//               ),
//               const SizedBox(height: AppSizes.md),
//               TextFormField(
//                 controller: _addressCtrl,
//                 decoration: const InputDecoration(labelText: 'Address'),
//                 maxLines: 2,
//               ),
//               const SizedBox(height: AppSizes.xl),
//               ElevatedButton(
//                 onPressed: _saving ? null : _save,
//                 child: _saving
//                     ? const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2.5,
//                         ),
//                       )
//                     : Text(_isEditing ? 'Update' : 'Save'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final String? customerId;
  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _saving = false;
  bool get _isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = context.read<CustomerProvider>().customers.firstWhere(
          (x) => x.id == widget.customerId,
        );
        _nameCtrl.text = c.name;
        _phoneCtrl.text = c.phone;
        _emailCtrl.text = c.email;
        _addressCtrl.text = c.address ?? '';
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<CustomerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final customer = CustomerModel(
      id: widget.customerId,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final ok = _isEditing
        ? await provider.updateCustomer(customer)
        : await provider.addCustomer(customer);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isEditing
                      ? 'Customer updated successfully'
                      : 'Customer created successfully',
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      router.pop();
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.error ??
                        (_isEditing ? 'Failed to update' : 'Failed to create'),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Same field styling recipe as the auth pages
    final cardColor = isDark
        ? Color.lerp(scheme.surface, Colors.white, 0.04)!
        : Colors.white;

    final fieldFill = isDark
        ? Color.lerp(cardColor, Colors.white, 0.06)!
        : Color.lerp(cardColor, scheme.primary, 0.04)!;

    final fieldBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.22);

    final fieldShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'New Customer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customers');
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? Color.lerp(scheme.surface, scheme.primary, 0.10)!
                  : Color.lerp(scheme.surface, scheme.primary, 0.06)!,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header banner ──────────────────────
                      _HeaderBanner(isEditing: _isEditing, scheme: scheme),
                      const SizedBox(height: 20),

                      // ── Basic info section ─────────────────
                      _SectionLabel(title: 'Basic information', scheme: scheme),
                      const SizedBox(height: 10),
                      _Card(
                        color: cardColor,
                        isDark: isDark,
                        child: Column(
                          children: [
                            _DecoratedField(
                              controller: _nameCtrl,
                              label: 'Full name',
                              hint: 'e.g. Ahmed Al Mansoori',
                              icon: Icons.person_outline,
                              enabled: !_saving,
                              fill: fieldFill,
                              border: fieldBorder,
                              focusBorder: scheme.primary,
                              scheme: scheme,
                              shadow: fieldShadow,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) =>
                                  Validators.required(v, field: 'Name'),
                            ),
                            const SizedBox(height: 14),
                            _DecoratedField(
                              controller: _phoneCtrl,
                              label: 'Phone number',
                              hint: 'e.g. 0501234567',
                              icon: Icons.phone_outlined,
                              enabled: !_saving,
                              fill: fieldFill,
                              border: fieldBorder,
                              focusBorder: scheme.primary,
                              scheme: scheme,
                              shadow: fieldShadow,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: Validators.phone,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Contact section ────────────────────
                      _SectionLabel(
                        title: 'Contact details (optional)',
                        scheme: scheme,
                      ),
                      const SizedBox(height: 10),
                      _Card(
                        color: cardColor,
                        isDark: isDark,
                        child: Column(
                          children: [
                            _DecoratedField(
                              controller: _emailCtrl,
                              label: 'Email address',
                              hint: 'e.g. customer@business.com',
                              icon: Icons.email_outlined,
                              enabled: !_saving,
                              fill: fieldFill,
                              border: fieldBorder,
                              focusBorder: scheme.primary,
                              scheme: scheme,
                              shadow: fieldShadow,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null;
                                }
                                return Validators.email(v);
                              },
                            ),
                            const SizedBox(height: 14),
                            _DecoratedField(
                              controller: _addressCtrl,
                              label: 'Address',
                              hint: 'Street, city, area',
                              icon: Icons.location_on_outlined,
                              enabled: !_saving,
                              fill: fieldFill,
                              border: fieldBorder,
                              focusBorder: scheme.primary,
                              scheme: scheme,
                              shadow: fieldShadow,
                              maxLines: 2,
                              textInputAction: TextInputAction.newline,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Primary action ─────────────────────
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            disabledBackgroundColor: scheme.primary.withValues(
                              alpha: 0.55,
                            ),
                            disabledForegroundColor: scheme.onPrimary
                                .withValues(alpha: 0.9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: _saving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEditing ? 'Updating...' : 'Saving...',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _isEditing
                                      ? 'Update Customer'
                                      : 'Save Customer',
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        _isEditing
                            ? 'Changes take effect immediately.'
                            : 'The customer will be available for new sales.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable presentational widgets
// ═══════════════════════════════════════════════════════════════

class _HeaderBanner extends StatelessWidget {
  final bool isEditing;
  final ColorScheme scheme;

  const _HeaderBanner({required this.isEditing, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isEditing ? Icons.edit_outlined : Icons.person_add_alt_1,
            color: scheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit customer' : 'Add new customer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEditing
                    ? 'Update the customer details below'
                    : 'Fill in the details to create a new customer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final ColorScheme scheme;

  const _SectionLabel({required this.title, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool isDark;

  const _Card({required this.child, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DecoratedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final Color fill;
  final Color border;
  final Color focusBorder;
  final ColorScheme scheme;
  final List<BoxShadow> shadow;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DecoratedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.fill,
    required this.border,
    required this.focusBorder,
    required this.scheme,
    required this.shadow,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder makeBorder(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface.withValues(alpha: 0.60),
    );
    final floatingLabelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: scheme.primary,
      letterSpacing: 0.3,
    );

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: labelStyle,
            floatingLabelStyle: floatingLabelStyle,
            floatingLabelBehavior: FloatingLabelBehavior.auto,

            hintText: hint,
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.35),
              fontSize: 13,
            ),

            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Icon(
                icon,
                size: 19,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),

            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),

            border: makeBorder(border),
            enabledBorder: makeBorder(border),
            focusedBorder: makeBorder(focusBorder, width: 1.8),
            errorBorder: makeBorder(AppColors.danger),
            focusedErrorBorder: makeBorder(AppColors.danger, width: 1.8),
            errorStyle: const TextStyle(
              color: AppColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }
}
