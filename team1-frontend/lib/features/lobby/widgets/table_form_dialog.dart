import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/models.dart';

/// Dialog for creating or editing a table.
///
/// When [table] is non-null, it is in edit mode and fields are pre-populated.
class TableFormDialog extends StatefulWidget {
  final int flightId;
  final EbsTable? table;
  final VoidCallback onSaved;

  const TableFormDialog({
    super.key,
    required this.flightId,
    this.table,
    required this.onSaved,
  });

  @override
  State<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tableNoCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _maxPlayersCtrl;
  late final TextEditingController _sbCtrl;
  late final TextEditingController _bbCtrl;
  late final TextEditingController _anteCtrl;
  late bool _isFeature;
  bool _saving = false;

  bool get _isEdit => widget.table != null;

  @override
  void initState() {
    super.initState();
    final t = widget.table;
    _tableNoCtrl = TextEditingController(text: '${t?.tableNo ?? 1}');
    _nameCtrl = TextEditingController(text: t?.name ?? 'Table 1');
    _maxPlayersCtrl = TextEditingController(text: '${t?.maxPlayers ?? 9}');
    _sbCtrl = TextEditingController(text: '${t?.smallBlind ?? 100}');
    _bbCtrl = TextEditingController(text: '${t?.bigBlind ?? 200}');
    _anteCtrl = TextEditingController(text: '${t?.anteAmount ?? 0}');
    _isFeature = t?.type == 'feature';
  }

  @override
  void dispose() {
    _tableNoCtrl.dispose();
    _nameCtrl.dispose();
    _maxPlayersCtrl.dispose();
    _sbCtrl.dispose();
    _bbCtrl.dispose();
    _anteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      // TODO: wire repository create/update call
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Table' : 'New Table'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tableNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Table No.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return (n != null && n > 0) ? null : 'Required';
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Table Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            (v != null && v.isNotEmpty) ? null : 'Required',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxPlayersCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Max Players',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n != null && n >= 2 && n <= 10) ? null : '2\u201310';
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sbCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Small Blind',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _bbCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Big Blind',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _anteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ante',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Feature Table'),
                  value: _isFeature,
                  onChanged: (v) => setState(() => _isFeature = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
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
