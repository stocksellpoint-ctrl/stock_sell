import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class AddEditUserScreen extends StatefulWidget {
  final String? userId;
  const AddEditUserScreen({super.key, this.userId});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _role = 'manager';
  bool _isActive = true;
  bool _saving = false;
  bool _obscure = true;

  bool get _isEditing => widget.userId != null;

  // ★ The dropdown must offer every role the backend can return, otherwise
  //   editing a user whose role is missing from this list crashes the widget.
  static const List<String> _allowedRoles = ['user', 'manager', 'admin'];

  static const Map<String, String> _roleLabels = {
    'user': 'User',
    'manager': 'Manager',
    'admin': 'Admin',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final users = context.read<UserProvider>().users;
        final matches = users.where((x) => x.id == widget.userId).toList();
        if (matches.isEmpty) {
          // Data disappeared (e.g. list refreshed) — bail to list
          if (mounted) context.pop();
          return;
        }
        final u = matches.first;

        setState(() {
          _nameCtrl.text = u.name;
          _emailCtrl.text = u.email;
          // ★ Normalize unknown roles so the dropdown never gets a value
          //   it doesn't have an item for.
          _role = _allowedRoles.contains(u.role) ? u.role : 'user';
          _isActive = u.isActive;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    bool ok;
    if (_isEditing) {
      ok = await provider.update(
        widget.userId!,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
        role: _role,
        isActive: _isActive,
      );
    } else {
      ok = await provider.create(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'User updated' : 'User created'),
          backgroundColor: AppColors.success,
        ),
      );
      router.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Add User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings/users');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _emailCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _passwordCtrl,
                enabled: !_saving,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'New password (leave blank to keep)'
                      : 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (_isEditing && (v == null || v.isEmpty)) return null;
                  if (v == null || v.length < 6) {
                    return 'At least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              // ★ Dropdown now offers all three roles, matching the backend.
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _allowedRoles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabels[r] ?? r),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) setState(() => _role = v);
                      },
              ),

              if (_isEditing) ...[
                const SizedBox(height: AppSizes.md),
                SwitchListTile(
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _isActive = v),
                  title: const Text('Account active'),
                  subtitle: const Text('Inactive users cannot log in'),
                ),
              ],

              const SizedBox(height: AppSizes.xl),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(_isEditing ? 'Update User' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}