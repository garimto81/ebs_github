import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/models.dart';

/// Dialog for creating or editing a tournament event.
///
/// Features: game mode selection (single/fixed rotation/dealer's choice),
/// mix presets, blind structure inline editor, flight auto-creation.
class EventFormDialog extends StatefulWidget {
  final int seriesId;
  final EbsEvent? event;
  final VoidCallback onSaved;

  const EventFormDialog({
    super.key,
    required this.seriesId,
    this.event,
    required this.onSaved,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  // Basic info
  late final TextEditingController _eventNoCtrl;
  late final TextEditingController _eventNameCtrl;
  late final TextEditingController _buyInCtrl;
  late final TextEditingController _tableSizeCtrl;
  late final TextEditingController _startingChipCtrl;
  late final TextEditingController _dayCountCtrl;

  // Game mode
  String _gameMode = 'single';
  int _gameType = 0;
  String _mixPreset = 'HORSE';
  String _rotationTrigger = 'Every Hand';
  String _tournType = 'standard';
  int _reentryLimit = 1;

  // Blind levels
  late List<_BlindLevel> _blindLevels;

  static const _mixPresets = [
    'HORSE',
    'TORSE',
    'HEROS',
    '8-Game',
    '9-Game (PPC)',
    '10-Game',
    'Pick Your PLO',
    'NL/PLO Mix',
    'Omaha Mix',
    'Stud Mix',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _eventNoCtrl = TextEditingController(text: '${e?.eventNo ?? 1}');
    _eventNameCtrl = TextEditingController(text: e?.eventName ?? '');
    _buyInCtrl = TextEditingController(text: e?.displayBuyIn ?? '0');
    _tableSizeCtrl = TextEditingController(text: '${e?.tableSize ?? 9}');
    _startingChipCtrl =
        TextEditingController(text: '${e?.startingChip ?? 20000}');
    _dayCountCtrl = TextEditingController(text: '1');
    if (e != null) {
      _gameMode = e.gameMode;
      _gameType = e.gameType;
    }
    _blindLevels = [
      _BlindLevel(level: 1, sb: 100, bb: 200, ante: 0, durationMin: 60),
      _BlindLevel(level: 2, sb: 200, bb: 400, ante: 0, durationMin: 60),
      _BlindLevel(level: 3, sb: 300, bb: 600, ante: 100, durationMin: 60),
    ];
  }

  @override
  void dispose() {
    _eventNoCtrl.dispose();
    _eventNameCtrl.dispose();
    _buyInCtrl.dispose();
    _tableSizeCtrl.dispose();
    _startingChipCtrl.dispose();
    _dayCountCtrl.dispose();
    super.dispose();
  }

  void _addBlindLevel() {
    final last = _blindLevels.isNotEmpty ? _blindLevels.last : null;
    setState(() {
      _blindLevels.add(_BlindLevel(
        level: _blindLevels.length + 1,
        sb: (last?.sb ?? 100) * 2,
        bb: (last?.bb ?? 200) * 2,
        ante: last?.ante ?? 0,
        durationMin: last?.durationMin ?? 60,
      ));
    });
  }

  void _removeBlindLevel(int index) {
    setState(() {
      _blindLevels.removeAt(index);
      for (int i = 0; i < _blindLevels.length; i++) {
        _blindLevels[i] = _blindLevels[i].copyWith(level: i + 1);
      }
    });
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade900,
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Tournament' : 'Create New Tournament',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _eventNoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Event No.',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _eventNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Tournament Name *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) =>
                                  (v != null && v.isNotEmpty)
                                      ? null
                                      : 'Required',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buyInCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Buy-In (\$)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tableSizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Table Size',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return (n != null && n >= 2 && n <= 10)
                                    ? null
                                    : '2\u201310';
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _startingChipCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Starting Chips',
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
                      const Divider(height: 24),

                      // Game Mode
                      const Text(
                        'Game Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          _radioChip('Single Game', 'single'),
                          _radioChip('Fixed Rotation', 'fixed_rotation'),
                          _radioChip("Dealer's Choice", 'dealers_choice'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_gameMode == 'single')
                        DropdownButtonFormField<int>(
                          initialValue: _gameType,
                          decoration: const InputDecoration(
                            labelText: 'Game Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: GameType.values
                              .map((g) => DropdownMenuItem(
                                    value: g.value,
                                    child: Text(g.label),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _gameType = v ?? 0),
                        ),
                      if (_gameMode != 'single') ...[
                        DropdownButtonFormField<String>(
                          initialValue: _mixPreset,
                          decoration: const InputDecoration(
                            labelText: 'Mix Preset',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _mixPresets
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _mixPreset = v ?? 'HORSE'),
                        ),
                        if (_gameMode == 'fixed_rotation') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _rotationTrigger,
                            decoration: const InputDecoration(
                              labelText: 'Rotation Trigger',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: ['Every Hand', 'Every Orbit', 'Every Level']
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _rotationTrigger = v ?? 'Every Hand'),
                          ),
                        ],
                      ],
                      const Divider(height: 24),

                      // Blind Structure
                      Row(
                        children: [
                          const Text(
                            'Blind Structure',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addBlindLevel,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Level'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildBlindTable(),
                      const Divider(height: 24),

                      // Days / Flights
                      const Text(
                        'Days / Flights',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _dayCountCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Number of Days',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return (n != null && n >= 1) ? null : 'Min 1';
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Flight(s) will be auto-created',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Tournament Type
                      const Text(
                        'Tournament Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          _tournTypeChip('Standard', 'standard'),
                          _tournTypeChip('Re-entry', 'reentry'),
                          _tournTypeChip('Freezeout', 'freezeout'),
                        ],
                      ),
                      if (_tournType == 'reentry') ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            initialValue: '$_reentryLimit',
                            decoration: const InputDecoration(
                              labelText: 'Re-entry Limit',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) =>
                                _reentryLimit = int.tryParse(v) ?? 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _gameMode == value,
      onSelected: (_) => setState(() => _gameMode = value),
    );
  }

  Widget _tournTypeChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _tournType == value,
      onSelected: (_) => setState(() => _tournType = value),
    );
  }

  Widget _buildBlindTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(50),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FixedColumnWidth(60),
        5: FixedColumnWidth(40),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            _BlindHeader('Lvl'),
            _BlindHeader('SB'),
            _BlindHeader('BB'),
            _BlindHeader('Ante'),
            _BlindHeader('Min'),
            _BlindHeader(''),
          ],
        ),
        for (int i = 0; i < _blindLevels.length; i++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${_blindLevels[i].level}',
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text('${_blindLevels[i].sb}',
                    textAlign: TextAlign.right),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text('${_blindLevels[i].bb}',
                    textAlign: TextAlign.right),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text('${_blindLevels[i].ante}',
                    textAlign: TextAlign.right),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text('${_blindLevels[i].durationMin}',
                    textAlign: TextAlign.right),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                onPressed: () => _removeBlindLevel(i),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
      ],
    );
  }
}

class _BlindHeader extends StatelessWidget {
  final String text;
  const _BlindHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _BlindLevel {
  int level;
  final int sb;
  final int bb;
  final int ante;
  final int durationMin;

  _BlindLevel({
    required this.level,
    required this.sb,
    required this.bb,
    required this.ante,
    required this.durationMin,
  });

  _BlindLevel copyWith({int? level}) {
    return _BlindLevel(
      level: level ?? this.level,
      sb: sb,
      bb: bb,
      ante: ante,
      durationMin: durationMin,
    );
  }
}
