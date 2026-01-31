import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/sync/screens/initial_sync_screen.dart';
import 'features/sync/providers/sync_provider.dart';
import 'shared/theme/app_theme.dart';

class MailstromApp extends ConsumerWidget {
  const MailstromApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'Mailstrom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (state) {
          if (!state.isAuthenticated) {
            return const LoginScreen();
          }
          final syncProgress = ref.watch(syncNotifierProvider);
          final syncNotifier = ref.read(syncNotifierProvider.notifier);
          return syncProgress.when(
            data: (progress) {
              // Show HomeScreen once fetching starts (senders populate progressively)
              if (syncNotifier.hasCompletedInitialSync ||
                  syncNotifier.hasStartedFetching) {
                return const HomeScreen();
              }
              // Only show InitialSyncScreen during the brief listing phase
              return const InitialSyncScreen();
            },
            loading: () => const InitialSyncScreen(),
            error: (_, _) => const HomeScreen(),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
