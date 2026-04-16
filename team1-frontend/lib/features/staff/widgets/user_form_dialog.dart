import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../providers/staff_provider.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final User? existingUser;
  const UserFormDialog({super.key, this.existingUser});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _passwordController;
  late String _role;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.existingUser;
    _emailController = TextEditingController(text: user?.email ?? '');
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _passwordController = TextEditingController();
    _role = user?.role ?? 'operator';
    _isActive = user?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_isEdit && (value == null || value.isEmpty)) {
      return 'Password is required for new users';
    }
    if (value != null && value.isNotEmpty && value.length < 8) {
      return 'Minimum 8 characters';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // TODO: wire repository
    // final payload = {
    //   'email': _emailController.text.trim(),
    //   'display_name': _displayNameController.text.trim(),
    //   'role': _role,
    //   'is_active': _isActive,
    //   if (!_isEdit && _passwordController.text.isNotEmpty)
    //     'password': _passwordController.text,
    // };
    //
    // if (_isEdit) {
    //   await ref.read(userRepositoryProvider).update(widget.existingUser!.userId, payload);
    // } else {
    //   await ref.read(userRepositoryProvider).create(payload);
    // }

    // Reload list
    ref.read(staffListProvider.notifier).fetch();

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'New User'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEdit,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // Display name
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),

                // Password (create only)
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                ],

                // Role
                Text(
                  'Role',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'admin', label: Text('Admin')),
                    ButtonSegment(value: 'operator', label: Text('Operator')),
                    ButtonSegment(value: 'viewer', label: Text('Viewer')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selected) {
                    setState(() => _role = selected.first);
                  },
                ),
                const SizedBox(height: 16),

                // Account status
                Text(
                  'Account Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: Text(_isActive ? 'Active' : 'Disabled'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
