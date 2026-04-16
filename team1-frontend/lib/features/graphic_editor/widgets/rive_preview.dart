import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../foundation/widgets/loading_state.dart';

/// Renders a .riv file from raw bytes.
///
/// Handles loading, error, and empty states. Preserves the artboard's
/// intrinsic aspect ratio via [FittedBox].
class RivePreview extends StatefulWidget {
  /// Raw bytes of the .riv file. Pass `null` to show a placeholder.
  final Uint8List? riveBytes;

  const RivePreview({super.key, this.riveBytes});

  @override
  State<RivePreview> createState() => _RivePreviewState();
}

class _RivePreviewState extends State<RivePreview> {
  Artboard? _artboard;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  @override
  void didUpdateWidget(RivePreview old) {
    super.didUpdateWidget(old);
    if (!_bytesEqual(widget.riveBytes, old.riveBytes)) {
      _loadRive();
    }
  }

  bool _bytesEqual(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    // Fast identity check — skip deep comparison for performance.
    return false;
  }

  void _loadRive() {
    final bytes = widget.riveBytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _artboard = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = RiveFile.import(ByteData.sublistView(bytes));
      setState(() {
        _artboard = file.mainArtboard;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _artboard = null;
        _error = 'Failed to load Rive file: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingState(message: 'Loading preview…');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      );
    }

    if (_artboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'No preview available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return Rive(artboard: _artboard!, fit: BoxFit.contain);
  }
}
