class AuthException implements Exception {
  final String message;
  final Object? cause;

  const AuthException(this.message, {this.cause});

  @override
  String toString() => 'AuthException: $message';
}
