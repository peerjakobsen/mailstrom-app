import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/email_category.dart';
import '../providers/stats_provider.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inboxStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat('#,##0');

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Inbox Statistics'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Failed to load stats: $error'),
            ),
            data: (stats) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Emails',
                          value: numberFormat.format(stats.totalEmails),
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Senders',
                          value: numberFormat.format(stats.totalSenders),
                          icon: Icons.people_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatCard(
                    label: 'Emails Deleted via Mailstrom',
                    value: numberFormat.format(stats.deletedEmails),
                    icon: Icons.delete_sweep_outlined,
                    iconColor: colorScheme.error,
                  ),

                  const SizedBox(height: 24),

                  // Category breakdown
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...stats.sortedCategories.map((entry) {
                    final category = EmailCategory.fromString(entry.key);
                    final percentage = stats.totalSenders > 0
                        ? (entry.value / stats.totalSenders * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Top domains
                  Text(
                    'Top 10 Senders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...stats.topDomains.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final domainName = entry.value.key;
                    final emailCount = entry.value.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${index + 1}.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              domainName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            numberFormat.format(emailCount),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
