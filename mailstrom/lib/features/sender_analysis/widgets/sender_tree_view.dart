import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database.dart';
import '../models/sender_group.dart';
import '../providers/sender_providers.dart';
import 'sender_tile.dart';

class SenderTreeView extends ConsumerWidget {
  const SenderTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(filteredSenderListProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ref.watch(senderSearchQueryProvider).isNotEmpty
                        ? 'No senders match your search'
                        : 'No senders found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final selection = ref.watch(senderSelectionProvider);
            final allSelected = group.senders
                .every((s) => selection.contains(s.email));

            return ExpansionTile(
              leading: Checkbox(
                value: allSelected && group.senders.isNotEmpty
                    ? true
                    : group.senders.any((s) => selection.contains(s.email))
                        ? null
                        : false,
                tristate: true,
                onChanged: (value) {
                  final emails =
                      group.senders.map((s) => s.email).toList();
                  if (value == true) {
                    ref
                        .read(senderSelectionProvider.notifier)
                        .selectAll(emails);
                  } else {
                    ref
                        .read(senderSelectionProvider.notifier)
                        .deselectAll(emails);
                  }
                },
              ),
              title: Text(
                group.domain,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDomainUnsubscribeButton(context, ref, group),
                  Text(
                    '${group.totalEmails}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              initiallyExpanded: groups.length <= 10,
              children: group.senders
                  .map((sender) => SenderTile(sender: sender))
                  .toList(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading senders: $error'),
      ),
    );
  }

  Widget _buildDomainUnsubscribeButton(
    BuildContext context,
    WidgetRef ref,
    SenderGroup group,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sendersWithLink =
        group.senders.where((s) => s.unsubscribeLink != null).toList();
    final sendersWithHttpLink = sendersWithLink
        .where((s) => !s.unsubscribeLink!.startsWith('mailto:'))
        .toList();
    final hasAnyLink = sendersWithLink.isNotEmpty;
    final allUnsubscribed =
        hasAnyLink && sendersWithLink.every((s) => s.isUnsubscribed);

    return IconButton(
      icon: Icon(
        allUnsubscribed ? Icons.check_circle_outline : Icons.unsubscribe,
        size: 16,
        color: !hasAnyLink
            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
            : allUnsubscribed
                ? colorScheme.onSurfaceVariant
                : colorScheme.tertiary,
      ),
      tooltip: !hasAnyLink
          ? 'No unsubscribe links found'
          : allUnsubscribed
              ? 'All unsubscribed'
              : sendersWithHttpLink.isEmpty
                  ? 'Open emails to find web unsubscribe links'
                  : 'Unsubscribe all (${sendersWithHttpLink.length})',
      onPressed: hasAnyLink
          ? () async {
              final targets = sendersWithHttpLink
                  .where((s) => !s.isUnsubscribed)
                  .toList();
              if (targets.isEmpty && sendersWithHttpLink.isNotEmpty) {
                // All HTTP senders already unsubscribed, re-open links
                for (final sender in sendersWithHttpLink) {
                  final uri = Uri.parse(sender.unsubscribeLink!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
                return;
              }
              for (final sender in targets) {
                final uri = Uri.parse(sender.unsubscribeLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  ref
                      .read(senderDaoProvider)
                      .markUnsubscribed(sender.email);
                }
              }
            }
          : null,
    );
  }
}
