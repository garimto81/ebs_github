// SG-003 Settings shared widget — label + editor wrapper.
//
// Used by the 6 Settings tabs to render a uniform <Label> → <Widget> pair
// while keeping each screen's business logic untouched.

import 'package:flutter/material.dart';

class SettingField extends StatelessWidget {
  const SettingField({
    super.key,
    required this.label,
    required this.child,
    this.helperText,
  });

  final String label;
  final Widget child;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 2),
            Text(
              helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
