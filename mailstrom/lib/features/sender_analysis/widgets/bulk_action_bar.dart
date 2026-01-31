import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/services/gmail_service.dart';
import '../../sync/providers/sync_provider.dart';
import '../providers/sender_providers.dart';

class BulkActionBar extends ConsumerWidget {
  const BulkActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(senderSelectionProvider);
    final sendersAsync = ref.watch(senderListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // Watch sync progress so the button re-enables when sync completes
    ref.watch(syncNotifierProvider);
    final isSyncing = !ref.read(syncNotifierProvider.notifier).hasCompletedInitialSync;

    final selectedSenders = sendersAsync.whenData(
      (senders) =>
          senders.where((s) => selection.contains(s.email)).toList(),
    );

    final totalEmails = selectedSenders.whenData(
      (senders) => senders.fold<int>(0, (sum, s) => sum + s.emailCount),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${selection.length} senders (${totalEmails.valueOrNull ?? 0} emails)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(senderSelectionProvider.notifier).clear();
            },
            child: const Text('Clear'),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: isSyncing
                ? 'Delete is available after sync completes'
                : '',
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              onPressed: isSyncing
                  ? null
                  : () => _showDeleteDialog(
                        context,
                        ref,
                        selection,
                        totalEmails.valueOrNull ?? 0,
                        selectedSenders.valueOrNull ?? [],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Set<String> selection,
    int totalEmails,
    List<SenderTableData> senders,
  ) {
    final senderNames = senders
        .map((s) => s.displayName ?? s.email)
        .toList()
      ..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete emails?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will move $totalEmails emails to Gmail Trash from:',
            ),
            const SizedBox(height: 8),
            ...senderNames.take(10).map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '\u2022 $name',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
            if (senderNames.length > 10)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  'and ${senderNames.length - 10} more...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Emails can be recovered from Trash within 30 days.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeBulkDelete(context, ref, senders);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkDelete(
    BuildContext context,
    WidgetRef ref,
    List<SenderTableData> senders,
  ) async {
    final gmailService = ref.read(gmailServiceProvider);
    final emailDao = ref.read(emailDaoProvider);
    final senderDao = ref.read(senderDaoProvider);

    var currentSender = '';
    var trashedCount = 0;
    var totalToTrash = 0;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Store setter so we can call it from outside
          _dialogSetState = setDialogState;
          _dialogContext = dialogContext;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSender.isNotEmpty
                      ? 'Deleting emails from $currentSender...'
                      : 'Preparing...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalToTrash > 0 ? trashedCount / totalToTrash : null,
                ),
                const SizedBox(height: 8),
                Text(
                  totalToTrash > 0
                      ? '$trashedCount / $totalToTrash emails'
                      : '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Small delay to let the dialog render
    await Future<void>.delayed(const Duration(milliseconds: 50));

    for (final sender in senders) {
      try {
        final emailIds = await emailDao.getEmailIdsBySender(sender.email);

        currentSender = sender.displayName ?? sender.email;
        trashedCount = 0;
        totalToTrash = emailIds.length;
        _dialogSetState?.call(() {});

        await gmailService.trashMessages(
          emailIds,
          onProgress: (completed, total) {
            trashedCount = completed;
            _dialogSetState?.call(() {});
          },
        );

        await emailDao.deleteEmailsBySender(sender.email);
        await senderDao.deleteSender(sender.email);
      } catch (e) {
        // Continue with other senders on failure
      }
    }

    // Close progress dialog
    if (_dialogContext != null && _dialogContext!.mounted) {
      Navigator.of(_dialogContext!).pop();
    }

    _dialogSetState = null;
    _dialogContext = null;

    ref.read(senderSelectionProvider.notifier).clear();
    ref.read(selectedSenderProvider.notifier).state = null;
  }

  // Mutable refs for updating the progress dialog from async code
  static void Function(void Function())? _dialogSetState;
  static BuildContext? _dialogContext;
}
