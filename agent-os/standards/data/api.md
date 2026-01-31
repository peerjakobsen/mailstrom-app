## Gmail API integration

- **Service Layer**: Wrap Gmail API calls in a dedicated service class (e.g., `GmailService`) injected via Riverpod provider
- **Pagination**: Use `nextPageToken` to paginate through `messages.list`; process in batches to avoid memory spikes
- **Batch Requests**: Use Gmail batch API for bulk operations (delete, archive, mark read) to minimize API calls
- **Rate Limiting**: Respect Gmail API quotas (250 quota units/second); implement request throttling and backoff
- **Token Refresh**: Handle OAuth token expiry transparently; refresh tokens before they expire and retry failed requests
- **Minimal Data Fetching**: Use `fields` parameter (partial responses) to request only the headers and metadata needed
- **Offline Resilience**: Cache fetched sender data and email metadata locally in SQLite; sync incrementally on reconnect
- **Error Mapping**: Map Gmail API error codes to app-specific exceptions for clean error handling upstream
- **Background Processing**: Run large mailbox analysis in isolates or background tasks to keep the UI responsive
