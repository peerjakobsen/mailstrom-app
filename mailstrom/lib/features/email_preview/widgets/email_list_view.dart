import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/email_providers.dart';

class EmailListView extends ConsumerWidget {
  final String senderEmail;

  const EmailListView({super.key, required this.senderEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailsAsync = ref.watch(emailListProvider(senderEmail));
    final colorScheme = Theme.of(context).colorScheme;

    return emailsAsync.when(
      data: (emails) {
        if (emails.isEmpty) {
          return const Center(child: Text('No emails from this sender'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$senderEmail (${emails.length} emails)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: emails.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final email = emails[index];
                  return ListTile(
                    title: Text(
                      email.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            email.isRead ? FontWeight.normal : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      email.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Text(
                      _formatDate(email.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    leading: Icon(
                      email.isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread,
                      size: 20,
                      color: email.isRead
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                    ),
                    onTap: () {
                      ref.read(selectedEmailIdProvider.notifier).state =
                          email.id;
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inHours < 24) {
      return timeago.format(date);
    }
    return DateFormat.yMMMd().format(date);
  }
}
