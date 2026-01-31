import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sender_providers.dart';
import '../widgets/sender_search_bar.dart';
import '../widgets/sender_tree_view.dart';
import '../widgets/bulk_action_bar.dart';

class SenderPanel extends ConsumerWidget {
  const SenderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(senderSelectionProvider);

    return Column(
      children: [
        const SenderSearchBar(),
        if (selection.isNotEmpty) const BulkActionBar(),
        const Expanded(child: SenderTreeView()),
      ],
    );
  }
}
