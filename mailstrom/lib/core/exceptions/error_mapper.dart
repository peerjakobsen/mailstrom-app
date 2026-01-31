import 'dart:io';

import 'auth_exception.dart';
import 'gmail_api_exception.dart';
import 'storage_exception.dart';

class ErrorMapper {
  static String userMessage(Object error) {
    if (error is AuthException) {
      return 'Authentication failed. Please sign in again.';
    }
    if (error is GmailApiException) {
      if (error.isRateLimited) {
        return 'Too many requests. Retrying automatically...';
      }
      if (error.isUnauthorized) {
        return 'Session expired. Please sign in again.';
      }
      if (error.isServerError) {
        return 'Gmail is temporarily unavailable. Please try again later.';
      }
      if (error.isNotFound) {
        return 'The requested email was not found.';
      }
      return 'Gmail error: ${error.message}';
    }
    if (error is StorageException) {
      return 'Storage error: ${error.message}';
    }
    if (error is SocketException) {
      return 'No internet connection. Showing cached data.';
    }
    return 'An unexpected error occurred.';
  }

  static bool isAuthError(Object error) {
    return error is AuthException ||
        (error is GmailApiException && error.isUnauthorized);
  }

  static bool isNetworkError(Object error) {
    return error is SocketException;
  }
}
