# Tech Stack

## Framework

- App Framework: Flutter 3.x
- Language: Dart
- Design System: Material 3
- Platform: macOS desktop (future: Windows, Linux)

## State Management

- State Management: Riverpod

## Local Storage

- Database: SQLite (via drift package)
- Use Case: Cache sender analysis, email metadata, and user preferences locally

## Gmail API Integration

- API Client: googleapis, googleapis_auth packages
- Authentication: Google OAuth 2.0
- Scopes: gmail.readonly, gmail.modify
- Credentials: Load from `google_oauth_credentials.json` (Google's standard format, not .env)
- Token Storage: macOS Keychain via flutter_secure_storage (for refresh tokens)

## Packages (Recommended)

- `drift`: Type-safe SQLite wrapper with reactive queries
- `flutter_secure_storage`: macOS Keychain integration for OAuth tokens
- `url_launcher`: Open unsubscribe links in browser
- `flutter_riverpod`: State management
- `googleapis`: Gmail API client
- `googleapis_auth`: OAuth 2.0 flow
- `timeago`: Human-readable relative timestamps

## UI

- Layout: Master-detail (tree left, content right)
- Theme: Light and dark mode support
- Title Bar: Native macOS integration
- Window: Responsive to resizing

## Data Model (Core Entities)

```dart
class Sender {
  String email;
  String? displayName;
  String domain;
  int emailCount;
  DateTime mostRecent;
  EmailCategory category;
  String? unsubscribeLink;
}

class Email {
  String id;
  String senderEmail;
  String subject;
  DateTime date;
  String snippet;
  bool isRead;
  String? unsubscribeLink;
}

class SyncState {
  DateTime lastSyncTime;
  String? historyId;
  int totalEmails;
  int processedEmails;
}

enum EmailCategory {
  newsletter,
  transactional,
  automated,
  personal,
  unknown
}
```

## API Constraints

- Gmail API daily quota: 1B units (generous but monitor during dev)
- `messages.list`: 5 units/request
- `messages.get`: 5 units/request
- Batch requests: Up to 100 requests per batch
- Strategy: Fetch metadata only (format=metadata, not full body) for initial analysis to minimize quota usage and speed up sync
