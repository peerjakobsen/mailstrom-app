import 'package:flutter/material.dart';

class KeyboardShortcutsOverlay extends StatelessWidget {
  const KeyboardShortcutsOverlay({super.key});

  static const _shortcuts = [
    ('Cmd + R', 'Refresh / sync'),
    ('Cmd + A', 'Select all visible senders'),
    ('Cmd + F', 'Focus search'),
    ('Cmd + ?', 'Show this help'),
    ('Escape', 'Clear selection'),
    ('Delete', 'Delete selected emails'),
    ('Cmd + Backspace', 'Delete selected emails'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.keyboard, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Keyboard Shortcuts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ..._shortcuts.map(
                (shortcut) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: _ShortcutKey(shortcut.$1),
                      ),
                      Expanded(
                        child: Text(
                          shortcut.$2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutKey extends StatelessWidget {
  final String keys;

  const _ShortcutKey(this.keys);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = keys.split(' + ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '+',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              parts[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
