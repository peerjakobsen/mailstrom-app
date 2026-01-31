import 'package:flutter/foundation.dart';

import '../exceptions/gmail_api_exception.dart';

Future<T> retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxRetries = 5,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      final statusCode = _extractStatusCode(e);

      if (statusCode == 401) {
        throw GmailApiException(
          e.toString(),
          statusCode: 401,
          cause: e,
        );
      }

      final isThrottled = statusCode == 429;
      final isServerError = statusCode != null && statusCode >= 500;

      if ((isThrottled || isServerError || statusCode == null) &&
          attempt < maxRetries) {
        attempt++;
        // Use longer initial backoff for 429 (5s base) vs others (1s base)
        final baseMs = isThrottled ? 5000 : 1000;
        final delay = Duration(milliseconds: baseMs * (1 << (attempt - 1)));
        debugPrint(
          'Retry $attempt/$maxRetries after ${delay.inSeconds}s '
          '(status: ${statusCode ?? 'unknown'})',
        );
        await Future<void>.delayed(delay);
        continue;
      }

      if (statusCode != null) {
        throw GmailApiException(
          e.toString(),
          statusCode: statusCode,
          cause: e,
        );
      }
      rethrow;
    }
  }
}

int? _extractStatusCode(Object error) {
  // Try to extract status from googleapis DetailedApiRequestError
  try {
    // ignore: avoid_dynamic_calls
    return (error as dynamic).status as int?;
  } catch (_) {
    return null;
  }
}
