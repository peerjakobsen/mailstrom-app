import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database.dart';
import '../../../core/models/email_category.dart';
import '../../email_preview/providers/email_providers.dart';
import '../providers/sender_providers.dart';

class SenderTile extends ConsumerWidget {
  final SenderTableData sender;

  const SenderTile({super.key, required this.sender});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSender = ref.watch(selectedSenderProvider);
    final isSelected = selectedSender == sender.email;
    final isChecked =
        ref.watch(senderSelectionProvider).contains(sender.email);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.only(left: 40, right: 8),
      leading: Checkbox(
        value: isChecked,
        onChanged: (_) {
          ref.read(senderSelectionProvider.notifier).toggle(sender.email);
        },
      ),
      title: Text(
        sender.displayName ?? sender.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: sender.displayName != null
          ? Text(
              sender.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CategoryBadge(category: EmailCategory.fromString(sender.category)),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              sender.isUnsubscribed
                  ? Icons.check_circle_outline
                  : Icons.unsubscribe,
              size: 16,
              color: sender.unsubscribeLink == null
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                  : sender.isUnsubscribed
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.tertiary,
            ),
            tooltip: sender.unsubscribeLink == null
                ? 'No unsubscribe link found'
                : sender.unsubscribeLink!.startsWith('mailto:')
                    ? 'Open an email to find web unsubscribe link'
                    : sender.isUnsubscribed
                        ? 'Unsubscribed — click to open link again'
                        : 'Unsubscribe',
            onPressed: sender.unsubscribeLink != null
                ? () async {
                    if (sender.unsubscribeLink!.startsWith('mailto:')) {
                      ref.read(selectedSenderProvider.notifier).state =
                          sender.email;
                      return;
                    }
                    final uri = Uri.parse(sender.unsubscribeLink!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                      ref
                          .read(senderDaoProvider)
                          .markUnsubscribed(sender.email);
                    }
                  }
                : null,
          ),
          Text(
            '${sender.emailCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      onTap: () {
        ref.read(selectedEmailIdProvider.notifier).state = null;
        ref.read(selectedSenderProvider.notifier).state = sender.email;
      },
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final EmailCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    if (category == EmailCategory.unknown) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: category.color,
        ),
      ),
    );
  }
}
