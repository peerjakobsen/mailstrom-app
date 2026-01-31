import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/master_detail_layout.dart';
import '../../sender_analysis/screens/sender_panel.dart';
import '../../email_preview/screens/email_panel.dart';
import '../../sync/providers/sync_provider.dart';
import '../../sync/widgets/sync_status_bar.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () {
          ref.read(syncNotifierProvider.notifier).refresh();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mailstrom'),
            actions: [
              const SyncStatusBar(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () => ref
                    .read(authNotifierProvider.notifier)
                    .signOut(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: const MasterDetailLayout(
            master: SenderPanel(),
            detail: EmailPanel(),
          ),
        ),
      ),
    );
  }
}
