## SQLite local storage

- **Schema Design**: Define tables for senders, email summaries, and sync state; use foreign keys between senders and emails
- **Drift or sqflite**: Use drift for type-safe queries and auto-generated code, or sqflite for simpler direct SQL access
- **Migrations**: Version the database schema; provide migration functions for schema changes between app versions
- **Timestamps**: Include `createdAt` and `updatedAt` columns on all tables for cache invalidation and debugging
- **Indexes**: Index frequently queried columns (sender email, domain, category) for fast tree view loading
- **Transactions**: Wrap bulk inserts (e.g., after fetching hundreds of emails) in transactions for performance and consistency
- **Cache Invalidation**: Track last sync time per account; re-fetch only new/changed emails on subsequent opens
- **Secure Storage**: Store OAuth refresh tokens and sensitive credentials in macOS Keychain via flutter_secure_storage, not in SQLite
- **Data Cleanup**: Provide a way to clear cached data when the user logs out or switches accounts
