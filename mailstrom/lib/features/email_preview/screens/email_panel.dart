import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sender_analysis/providers/sender_providers.dart';
import '../providers/email_providers.dart';
import '../widgets/email_list_view.dart';
import '../widgets/email_detail_view.dart';

class EmailPanel extends ConsumerWidget {
  const EmailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSender = ref.watch(selectedSenderProvider);
    final selectedEmailId = ref.watch(selectedEmailIdProvider);

    ref.listen<String?>(selectedSenderProvider, (previous, next) {
      if (previous != next) {
        ref.read(selectedEmailIdProvider.notifier).state = null;
      }
    });

    if (selectedSender == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a sender to view emails',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (selectedEmailId != null) {
      return EmailDetailView(
        emailId: selectedEmailId,
        onBack: () {
          ref.read(selectedEmailIdProvider.notifier).state = null;
        },
      );
    }

    return EmailListView(senderEmail: selectedSender);
  }
}
