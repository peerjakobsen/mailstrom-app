# Mailstrom Phase 1 — Shape

## Problem
Gmail users accumulate thousands of emails from senders they no longer care about. Gmail's UI makes it tedious to clean up by sender — you have to search, select, delete, repeat.

## Solution
A macOS desktop app that:
1. Connects to Gmail via OAuth
2. Analyzes inbox by sender (grouped by domain)
3. Shows email counts, most recent date, category
4. Lets users bulk-select senders and delete all their emails
5. Surfaces unsubscribe links for easy cleanup

## Scope — What's IN
- Gmail OAuth with secure token storage
- Full inbox sync with incremental updates
- Sender tree grouped by domain
- Email preview (list + detail)
- Bulk delete (move to Gmail Trash)
- Unsubscribe link extraction and opening
- Search and sort senders
- Offline viewing after initial sync
- Light and dark theme

## Scope — What's OUT (Phase 2+)
- Multiple account support
- Gmail labels/filters management
- Undo delete (Gmail Trash has 30-day recovery)
- Custom categorization rules
- Windows/Linux support
- Auto-unsubscribe (clicking mailto: links)
- Email forwarding or archiving
- Statistics dashboard

## Architecture Decisions
- **Drift (SQLite) as source of truth**: Enables offline access, fast queries, reactive streams. Gmail API is write-only into DB.
- **Riverpod for state management**: Type-safe, testable, supports async providers natively.
- **Master-detail layout**: Familiar pattern for email-like apps, efficient use of desktop screen space.
- **googleapis_auth for OAuth**: Official Google package, handles desktop consent flow properly.
- **flutter_secure_storage for tokens**: Uses macOS Keychain, most secure option for credentials.
- **Batch operations**: Gmail API supports batch requests, critical for performance with large inboxes.

## Constraints
- Gmail API rate limit: 250 quota units/second per user
- messages.list = 5 units, messages.get = 5 units, messages.trash = 5 units
- Batch requests: max 100 per batch, counts as 100 individual requests
- History API: may return 404 if historyId too old, requires full sync fallback
- macOS only for Phase 1
- OAuth credentials must not be committed to source control
