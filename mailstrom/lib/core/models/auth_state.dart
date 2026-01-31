enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? userEmail;
  final String? error;

  const AuthState({
    required this.status,
    this.userEmail,
    this.error,
  });

  const AuthState.initial()
      : status = AuthStatus.loading,
        userEmail = null,
        error = null;

  const AuthState.authenticated({required String email})
      : status = AuthStatus.authenticated,
        userEmail = email,
        error = null;

  const AuthState.unauthenticated({this.error})
      : status = AuthStatus.unauthenticated,
        userEmail = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}
