# Product Roadmap

## Phase 1: MVP

Core functionality to connect, analyze, and clean up a Gmail inbox.

- **Gmail OAuth Authentication**: Google OAuth 2.0 flow with gmail.readonly and gmail.modify scopes; refresh token stored in Application Support directory
- **Sender Analysis & Tree View**: Fetch emails, group by sender domain and address, display as expandable tree with email counts
- **Email Preview Panel**: Show email list for selected sender with subject, date, and snippet; expand to view full email
- **Bulk Delete**: Select one or more senders and move all their emails to Trash (recoverable for 30 days) with confirmation dialog
- **Unsubscribe Link Extraction**: Detect List-Unsubscribe header and body unsubscribe links; open in browser for user to complete
- **Pagination & Rate Limiting**: Handle Gmail API pagination for mailboxes with 10k+ emails; respect rate limits with exponential backoff
- **Sync Progress UI**: Show progress during initial mailbox analysis (X of Y emails processed)
- **Incremental Sync**: After initial load, fetch only new emails since last sync using Gmail history API
- **Search & Sort**: Search/filter senders in tree view; sort by count, name, or most recent

## Phase 2: Post-Launch

Enhanced analysis, additional bulk actions, and production hardening.

- **macOS Code Signing & Keychain Storage**: Apple Developer certificate, proper provisioning profile, migrate token storage from file-based to macOS Keychain via flutter_secure_storage for production-grade credential security
- **Smart Categorization**: Auto-detect email types (newsletter, transactional, automated, personal) using unsubscribe headers and content patterns
- **Category Filtering**: Filter the tree view by category; "Newsletter Nuke Mode" to show only unsubscribable senders
- **Statistics Dashboard**: Total emails analyzed, top senders by volume, category breakdown chart, space reclaimed tracker
- **Additional Bulk Actions**: Archive all, mark as read for selected senders
- **Keyboard Shortcuts**: Cmd+A select all, Delete key, navigation shortcuts

## Phase 3: Future

Expansion and advanced features.

- Multiple Gmail account support
- Auto-unsubscribe via headless browser
- Scheduled cleanup rules (auto-delete from sender after N days)
- Export sender list to CSV
- "Inbox Zero" game mode with progress tracking
- Windows and Linux desktop support
- iOS/Android companion app
