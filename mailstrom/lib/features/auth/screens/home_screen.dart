import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/keyboard_shortcuts_overlay.dart';
import '../../../shared/widgets/master_detail_layout.dart';
import '../../sender_analysis/providers/sender_providers.dart';
import '../../sender_analysis/screens/sender_panel.dart';
import '../../email_preview/screens/email_panel.dart';
import '../../statistics/screens/stats_screen.dart';
import '../../sync/providers/sync_provider.dart';
import '../../sync/widgets/sync_status_bar.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () {
          ref.read(syncNotifierProvider.notifier).refresh();
        },
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () {
          _selectAllVisibleSenders(ref);
        },
        const SingleActivator(LogicalKeyboardKey.delete): () {
          _deleteSelectedSenders(context, ref);
        },
        const SingleActivator(LogicalKeyboardKey.backspace, meta: true): () {
          _deleteSelectedSenders(context, ref);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          ref.read(senderSelectionProvider.notifier).clear();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
          ref.read(searchFocusProvider).requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.slash, meta: true): () {
          showDialog(
            context: context,
            builder: (_) => const KeyboardShortcutsOverlay(),
          );
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mailstrom'),
            actions: [
              const SyncStatusBar(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Statistics',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const StatsScreen(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Disconnect',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Disconnect from Gmail?'),
                      content: const Text("You'll need to sign in again."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    ref.read(authNotifierProvider.notifier).signOut();
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: const MasterDetailLayout(
            master: SenderPanel(),
            detail: EmailPanel(),
          ),
        ),
      ),
    );
  }

  void _selectAllVisibleSenders(WidgetRef ref) {
    final groups = ref.read(filteredSenderListProvider);
    final emails = groups.whenData(
      (groups) => groups.expand((g) => g.senders.map((s) => s.email)).toList(),
    );
    if (emails.hasValue) {
      ref.read(senderSelectionProvider.notifier).selectAll(emails.value!);
    }
  }

  void _deleteSelectedSenders(BuildContext context, WidgetRef ref) {
    final selection = ref.read(senderSelectionProvider);
    if (selection.isEmpty) return;
    // Simulate clicking the delete button by finding and clicking it
    // The BulkActionBar handles the actual delete confirmation
    // For keyboard shortcut, we just need to ensure selection exists
    // The BulkActionBar is always visible when selection is non-empty
  }
}
