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
    // Watch sync progress so buttons re-enable when sync completes
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
          _ActionButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Mark Read',
            isSyncing: isSyncing,
            tooltip: 'Mark all emails as read',
            onPressed: () => _showConfirmDialog(
              context,
              ref,
              title: 'Mark emails as read?',
              action: 'mark as read',
              senders: selectedSenders.valueOrNull ?? [],
              totalEmails: totalEmails.valueOrNull ?? 0,
              onConfirm: () => _executeBulkAction(
                context,
                ref,
                senders: selectedSenders.valueOrNull ?? [],
                actionLabel: 'Marking as read',
                execute: (gmailService, emailIds, onProgress) async {
                  await gmailService.markAsRead(
                    emailIds,
                    onProgress: onProgress,
                  );
                },
                postProcess: (ref, sender, emailIds) async {
                  final emailDao = ref.read(emailDaoProvider);
                  await emailDao.markEmailsAsReadBySender(sender.email);
                },
                clearSelection: false,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.archive_outlined,
            label: 'Archive',
            isSyncing: isSyncing,
            tooltip: 'Archive all emails (remove from inbox)',
            onPressed: () => _showConfirmDialog(
              context,
              ref,
              title: 'Archive emails?',
              action: 'archive',
              senders: selectedSenders.valueOrNull ?? [],
              totalEmails: totalEmails.valueOrNull ?? 0,
              description: 'Emails will be removed from your inbox but remain in All Mail.',
              onConfirm: () => _executeBulkAction(
                context,
                ref,
                senders: selectedSenders.valueOrNull ?? [],
                actionLabel: 'Archiving',
                execute: (gmailService, emailIds, onProgress) async {
                  await gmailService.archiveMessages(
                    emailIds,
                    onProgress: onProgress,
                  );
                },
                postProcess: (ref, sender, emailIds) async {
                  final emailDao = ref.read(emailDaoProvider);
                  final senderDao = ref.read(senderDaoProvider);
                  await emailDao.deleteEmailsBySender(sender.email);
                  await senderDao.deleteSender(sender.email);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            isSyncing: isSyncing,
            tooltip: 'Move to Gmail Trash',
            onPressed: () => _showConfirmDialog(
              context,
              ref,
              title: 'Delete emails?',
              action: 'delete',
              senders: selectedSenders.valueOrNull ?? [],
              totalEmails: totalEmails.valueOrNull ?? 0,
              description: 'Emails can be recovered from Trash within 30 days.',
              onConfirm: () => _executeBulkAction(
                context,
                ref,
                senders: selectedSenders.valueOrNull ?? [],
                actionLabel: 'Deleting',
                execute: (gmailService, emailIds, onProgress) async {
                  await gmailService.trashMessages(
                    emailIds,
                    onProgress: onProgress,
                  );
                },
                postProcess: (ref, sender, emailIds) async {
                  final emailDao = ref.read(emailDaoProvider);
                  final senderDao = ref.read(senderDaoProvider);
                  final syncStateDao = ref.read(syncStateDaoProvider);
                  await emailDao.deleteEmailsBySender(sender.email);
                  await senderDao.deleteSender(sender.email);
                  await syncStateDao.incrementDeletedCount(emailIds.length);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String action,
    required List<SenderTableData> senders,
    required int totalEmails,
    String? description,
    required VoidCallback onConfirm,
  }) {
    final senderNames = senders
        .map((s) => s.displayName ?? s.email)
        .toList()
      ..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will $action $totalEmails emails from:',
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
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
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
              onConfirm();
            },
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkAction(
    BuildContext context,
    WidgetRef ref, {
    required List<SenderTableData> senders,
    required String actionLabel,
    required Future<void> Function(
      GmailService gmailService,
      List<String> emailIds,
      void Function(int, int) onProgress,
    ) execute,
    required Future<void> Function(
      WidgetRef ref,
      SenderTableData sender,
      List<String> emailIds,
    ) postProcess,
    bool clearSelection = true,
  }) async {
    final gmailService = ref.read(gmailServiceProvider);
    final emailDao = ref.read(emailDaoProvider);

    var currentSender = '';
    var processedCount = 0;
    var totalToProcess = 0;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          _dialogSetState = setDialogState;
          _dialogContext = dialogContext;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSender.isNotEmpty
                      ? '$actionLabel emails from $currentSender...'
                      : 'Preparing...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalToProcess > 0
                      ? processedCount / totalToProcess
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  totalToProcess > 0
                      ? '$processedCount / $totalToProcess emails'
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
        processedCount = 0;
        totalToProcess = emailIds.length;
        _dialogSetState?.call(() {});

        await execute(
          gmailService,
          emailIds,
          (completed, total) {
            processedCount = completed;
            _dialogSetState?.call(() {});
          },
        );

        await postProcess(ref, sender, emailIds);
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

    if (clearSelection) {
      ref.read(senderSelectionProvider.notifier).clear();
      ref.read(selectedSenderProvider.notifier).state = null;
    }
  }

  // Mutable refs for updating the progress dialog from async code
  static void Function(void Function())? _dialogSetState;
  static BuildContext? _dialogContext;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSyncing;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isSyncing,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isSyncing
          ? '$label is available after sync completes'
          : tooltip,
      child: FilledButton.tonalIcon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: isSyncing ? null : onPressed,
      ),
    );
  }
}
