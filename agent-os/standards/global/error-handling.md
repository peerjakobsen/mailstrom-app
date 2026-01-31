## Dart/Flutter error handling

- **User-Friendly Messages**: Show clear, actionable error messages in the UI (SnackBars, dialogs) without exposing technical details
- **Typed Exceptions**: Define custom exception classes for distinct error categories (e.g., `AuthException`, `GmailApiException`, `StorageException`)
- **Fail Fast**: Validate inputs and check preconditions early; use `assert` for development-time invariants
- **AsyncNotifier Error States**: Use Riverpod's `AsyncValue.error` state to represent and handle errors in async providers
- **Gmail API Errors**: Handle rate limits (429), auth expiry (401), and quota exceeded errors with appropriate retry or re-auth flows
- **Graceful Degradation**: If cached data is available, show stale data with a refresh indicator rather than a blank error screen
- **Retry with Backoff**: Implement exponential backoff for transient Gmail API failures
- **Dispose Resources**: Cancel subscriptions, close streams, and dispose controllers in widget `dispose()` methods
- **Never Swallow Errors**: Avoid empty catch blocks; at minimum log the error for debugging
