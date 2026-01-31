import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../../core/database/database.dart';
import '../../../core/exceptions/auth_exception.dart';
import '../../../core/models/auth_state.dart';
import '../../../core/services/auth_service.dart';

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() async {
    final authService = ref.read(authServiceProvider);
    try {
      final client = await authService.restoreSession();
      if (client != null) {
        return AuthState.authenticated(
          email: await authService.getUserEmail(client),
        );
      }
    } on AuthException catch (_) {
      // Could not restore — fall through to unauthenticated
    }
    return const AuthState.unauthenticated();
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      final client = await authService.signIn();
      final email = await authService.getUserEmail(client);
      return AuthState.authenticated(email: email);
    });
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    final db = ref.read(databaseProvider);
    await authService.signOut();
    await db.clearAll();
    state = const AsyncValue.data(AuthState.unauthenticated());
  }
}

final authenticatedClientProvider = FutureProvider<AuthClient?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.restoreSession();
});
