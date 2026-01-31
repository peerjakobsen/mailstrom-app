import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';

class InitialSyncScreen extends ConsumerWidget {
  const InitialSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Syncing your inbox',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              syncState.when(
                data: (progress) => Column(
                  children: [
                    Text(
                      progress.phaseLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: progress.totalMessages > 0
                          ? progress.progress
                          : null,
                    ),
                    if (progress.totalMessages > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${progress.processedMessages} / ${progress.totalMessages} emails',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                loading: () => const Column(
                  children: [
                    Text('Connecting to Gmail...'),
                    SizedBox(height: 24),
                    LinearProgressIndicator(),
                  ],
                ),
                error: (error, _) => Column(
                  children: [
                    Text(
                      'Sync failed: $error',
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref
                          .read(syncNotifierProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
