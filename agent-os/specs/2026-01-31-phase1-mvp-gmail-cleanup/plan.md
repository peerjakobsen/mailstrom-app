# Mailstrom Phase 1 MVP — Implementation Plan

## Overview
Full implementation of Mailstrom Phase 1 — a Flutter/Dart macOS desktop app that connects to Gmail via OAuth, analyzes the inbox by sender, and lets users bulk-delete and unsubscribe.

**Tech stack:** Flutter 3.x, Dart, Riverpod, Drift (SQLite), Gmail API (googleapis), Material 3, macOS desktop

## Architecture

- **Drift database as source of truth** — All UI reads from SQLite via reactive Drift queries. Gmail API writes into DB. Works offline after initial sync.
- **GmailService wrapper** — Single service class for all Gmail API calls, handles pagination, rate limiting, token refresh. Injected via Riverpod.
- **SyncNotifier** — AsyncNotifier managing initial + incremental sync state and progress.
- **Master-detail layout** — Sender tree (left) + email content (right). Selected sender drives right panel.
- **OAuth via googleapis_auth** — clientViaUserConsent for desktop flow, tokens in macOS Keychain via flutter_secure_storage.

## Directory Structure

```
lib/
  main.dart, app.dart
  features/
    auth/       (providers/, screens/, widgets/)
    sender_analysis/  (providers/, screens/, widgets/, models/)
    email_preview/    (providers/, screens/, widgets/)
    sync/       (providers/, widgets/)
  core/
    services/   (auth_service, gmail_service)
    models/     (sender, email_summary, sync_state, email_category, auth_state)
    database/   (tables, database, daos/)
    exceptions/ (auth, gmail_api, storage)
    utils/      (rate_limiter, retry, email_parser, unsubscribe_parser)
  shared/
    widgets/    (master_detail_layout, error_banner, refresh_button)
    theme/      (app_theme)
```

## Tasks (17 total)
1. Save Spec Documentation
2. Flutter Project Init & Dependencies
3. Core Data Models & Exceptions
4. Drift Database Setup
5. Theme & App Shell
6. Google OAuth Authentication
7. Gmail Service Layer
8. Sync Engine — Initial Full Sync
9. Sender Tree View
10. Email Preview Panel
11. Bulk Delete
12. Unsubscribe Link Extraction
13. Search & Sort
14. Incremental Sync
15. Sync Progress UI Polish
16. Error Handling & Edge Cases
17. Integration Testing & Polish

## Dependency Order
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 13
7 → 11 (Bulk Delete), 12 (Unsubscribe)
8 → 14 (Incremental Sync), 15 (Sync UI Polish)
16, 17 follow all above
