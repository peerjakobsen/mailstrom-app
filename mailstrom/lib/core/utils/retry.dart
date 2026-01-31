import '../exceptions/gmail_api_exception.dart';

Future<T> retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
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

      if ((statusCode == 429 ||
              (statusCode != null && statusCode >= 500)) &&
          attempt < maxRetries) {
        attempt++;
        final delay = Duration(milliseconds: 1000 * (1 << attempt));
        await Future<void>.delayed(delay);
        continue;
      }

      if (attempt < maxRetries && statusCode == null) {
        attempt++;
        final delay = Duration(milliseconds: 1000 * (1 << attempt));
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
