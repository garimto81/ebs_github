import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../providers/player_provider.dart';

/// Dialog for assigning a player to an empty seat at a table.
///
/// Features: player search with autocomplete, seat number selection,
/// save action.
class AddPlayerDialog extends ConsumerStatefulWidget {
  final int tableId;
  final List<int> emptySeats;
  final VoidCallback onSaved;

  const AddPlayerDialog({
    super.key,
    required this.tableId,
    required this.emptySeats,
    required this.onSaved,
  });

  @override
  ConsumerState<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends ConsumerState<AddPlayerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedPlayerId;
  int? _selectedSeat;
  bool _saving = false;
  bool _searching = false;
  List<Player> _searchResults = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      // Trigger player search via provider
      await ref.read(playerListProvider.notifier).fetch(query: query.trim());
      final results = ref.read(playerListProvider);
      results.whenData((players) {
        if (mounted) {
          setState(() => _searchResults = players);
        }
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedPlayerId == null || _selectedSeat == null) return;
    setState(() => _saving = true);
    try {
      // TODO: wire repository seat assignment call
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Player'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Player search
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search player...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _handleSearch,
            ),
            const SizedBox(height: 8),

            // Results
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = _searchResults[index];
                    final isSelected =
                        _selectedPlayerId == player.playerId;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      title: Text(
                        '${player.firstName} ${player.lastName}',
                      ),
                      subtitle: Text(
                        '${player.wsopId ?? ''} \u00b7 ${player.countryCode ?? ''}',
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPlayerId = player.playerId;
                        });
                      },
                    );
                  },
                ),
              )
            else if (_searchCtrl.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No players found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 12),

            // Seat selection
            DropdownButtonFormField<int>(
              value: _selectedSeat,
              decoration: const InputDecoration(
                labelText: 'Select Seat',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.emptySeats
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('Seat $s'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSeat = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              (_selectedPlayerId != null && _selectedSeat != null && !_saving)
                  ? _handleSave
                  : null,
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
