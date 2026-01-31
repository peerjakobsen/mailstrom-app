import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/database/database.dart';
import '../providers/sync_provider.dart';

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        syncState.when(
          data: (progress) {
            if (progress.isActive) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.totalMessages > 0
                          ? progress.progress
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progress.totalMessages > 0
                        ? '${progress.phaseLabel} ${progress.processedMessages} / ${progress.totalMessages}'
                        : progress.phaseLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }
            return FutureBuilder(
              future: ref.read(syncStateDaoProvider).getSyncState(),
              builder: (context, snapshot) {
                final lastSync = snapshot.data?.lastSyncTime;
                if (lastSync == null) return const SizedBox.shrink();
                return Text(
                  'Synced ${timeago.format(lastSync)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                );
              },
            );
          },
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => Icon(
            Icons.sync_problem,
            size: 16,
            color: colorScheme.error,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh (Cmd+R)',
          onPressed: () =>
              ref.read(syncNotifierProvider.notifier).refresh(),
        ),
      ],
    );
  }
}
