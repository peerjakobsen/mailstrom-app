class GmailApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const GmailApiException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;
  bool get isServerError =>
      statusCode != null && statusCode! >= 500;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() =>
      'GmailApiException($statusCode): $message';
}
