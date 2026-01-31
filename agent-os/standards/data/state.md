## Riverpod state management

- **Provider Types**: Use `Provider` for computed/derived values, `StateProvider` for simple state, `NotifierProvider`/`AsyncNotifierProvider` for complex state with logic
- **AsyncValue for API State**: Use `AsyncValue` (loading, data, error) for all Gmail API-backed state to handle loading and error states consistently
- **Scoped Providers**: Scope providers to the narrowest necessary lifetime; avoid global state when feature-scoped state suffices
- **Separation of Concerns**: Keep business logic in Notifier classes, not in widgets; widgets should only read state and dispatch actions
- **Ref.watch vs Ref.read**: Use `ref.watch` in build methods for reactive rebuilds; use `ref.read` in callbacks and event handlers
- **Avoid Side Effects in Build**: Never trigger API calls or mutations inside `build()`; use `ref.listen` or Notifier methods for side effects
- **Provider Naming**: Name providers descriptively (e.g., `senderListProvider`, `emailPreviewProvider`, `authStateProvider`)
- **Dispose and Cancel**: Use `ref.onDispose` to cancel timers, close streams, and clean up resources in providers
- **Family Providers**: Use `.family` for parameterized providers (e.g., emails by sender ID) rather than creating separate providers
