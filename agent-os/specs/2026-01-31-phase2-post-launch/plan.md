# Mailstrom Phase 2: Post-Launch Features — Implementation Plan

## Overview
Six post-launch features adding smart categorization, keychain token storage, category filtering, statistics dashboard, additional bulk actions, and keyboard shortcuts to the existing Mailstrom macOS desktop app.

**Tech stack:** Flutter 3.x, Dart, Riverpod, Drift (SQLite), Gmail API (googleapis), flutter_secure_storage, Material 3, macOS desktop

## Architecture Notes

- **CategoryEngine already exists** — 5-layer heuristic engine is implemented in `core/utils/category_engine.dart`. Phase 2 wires it into sync and adds re-categorization of existing senders.
- **Category color coding** — `EmailCategory` enum already has colors defined. Phase 2 displays them on sender tiles.
- **Keychain migration** — Replace file-based `TokenStorage` with `flutter_secure_storage`, auto-migrate tokens on first launch.
- **Bulk actions via messages.modify** — Archive removes INBOX label, Mark as Read removes UNREAD label. Both use existing `GmailService` patterns.
- **Stats from existing DAOs** — No new tables. Aggregate queries on sender_table and sync_state_table plus a `deletedEmailCount` column on sync_state.
- **Keyboard shortcuts** — Flutter `Shortcuts` + `Actions` widgets wrapping the home screen.

## Tasks (9 total)

### Task 1: Save Phase 2 Spec Documentation
Save shape, plan, standards, and references to `agent-os/specs/2026-01-31-phase2-post-launch/`.

**Files:**
- `agent-os/specs/2026-01-31-phase2-post-launch/shape.md`
- `agent-os/specs/2026-01-31-phase2-post-launch/plan.md`
- `agent-os/specs/2026-01-31-phase2-post-launch/standards.md`
- `agent-os/specs/2026-01-31-phase2-post-launch/references.md`

---

### Task 2: Keychain Token Storage & Migration
Replace file-based `TokenStorage` with `flutter_secure_storage` backed by macOS Keychain. Auto-migrate existing tokens on first read.

**Changes:**
- Add `flutter_secure_storage` to `pubspec.yaml`
- Rewrite `core/services/token_storage.dart` to use `FlutterSecureStorage`
- Add migration logic: on `read()`, check keychain first; if empty, read from old file, write to keychain, delete old file
- Update `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` with keychain-access-groups
- Add code signing setup instructions to `agent-os/specs/2026-01-31-phase2-post-launch/CODE_SIGNING.md`

**Files:**
- `pubspec.yaml` (add dependency)
- `lib/core/services/token_storage.dart` (rewrite)
- `macos/Runner/DebugProfile.entitlements` (update)
- `macos/Runner/Release.entitlements` (update)

---

### Task 3: Wire CategoryEngine into Sync
The `CategoryEngine` exists but may not be fully integrated into the sync pipeline. Ensure every sender gets categorized during sync and add one-time re-categorization for existing senders on upgrade.

**Changes:**
- Verify `CategoryEngine.categorize()` is called during initial and incremental sync when upserting senders
- Add `re-categorizeAllSenders()` method to `SenderDao` that reads all senders from DB, runs each through `CategoryEngine`, and updates the category column
- Call re-categorization once on app start (track via a `schemaMigrationVersion` field in sync_state or a simple shared preference flag)
- Ensure `category_engine.dart` includes the `automated` category detection (already present — verify completeness)

**Files:**
- `lib/core/database/daos/sender_dao.dart` (add re-categorize method)
- `lib/features/sync/providers/sync_provider.dart` (trigger re-categorization)
- `lib/core/utils/category_engine.dart` (verify, no changes expected)

---

### Task 4: Category Color Coding on Sender Tiles
Display the category as a colored dot or chip on each sender tile in the tree view.

**Changes:**
- Import `EmailCategory` in `sender_tile.dart`
- Add a small colored dot (8px circle) or chip next to the sender name showing `EmailCategory.fromString(sender.category).color`
- Add tooltip on hover showing the category display name
- Ensure color contrast works in both light and dark themes

**Files:**
- `lib/features/sender_analysis/widgets/sender_tile.dart` (update)

---

### Task 5: Category Filtering & Newsletter Nuke Mode
Add category-based filtering to the sender tree, composable with existing unsubscribe filter. Add a "Newsletter Nuke Mode" toggle.

**Changes:**
- Add `senderCategoryFilterProvider` as `StateProvider<EmailCategory?>` (null = all categories)
- Add `newsletterNukeModeProvider` as `StateProvider<bool>`
- Update `filteredSenderListProvider` to apply category filter and nuke mode:
  - Category filter: if set, only show senders matching that category
  - Newsletter Nuke Mode: filter to `newsletter` category AND `unsubscribeLink != null`
- Add category filter dropdown to sender panel header (alongside existing sort/filter controls)
- Add "Newsletter Nuke Mode" toggle button with distinct styling (e.g., warning color)
- Category filter and unsubscribe filter compose (both conditions must pass)

**Files:**
- `lib/features/sender_analysis/providers/sender_providers.dart` (add providers, update filter logic)
- `lib/features/sender_analysis/screens/sender_panel.dart` (add UI controls)
- `lib/features/sender_analysis/widgets/sender_search_bar.dart` (may need updates for filter row)

---

### Task 6: Additional Bulk Actions (Archive & Mark as Read)
Add Archive and Mark as Read bulk actions alongside existing Delete.

**Changes:**
- Add `archiveMessages(List<String> messageIds)` to `GmailService` — calls `messages.modify` to remove `INBOX` label
- Add `markAsRead(List<String> messageIds)` to `GmailService` — calls `messages.modify` to remove `UNREAD` label
- Both methods use batching (100 per batch) with rate limiting, matching existing `trashMessages` pattern
- Add Archive and Mark as Read buttons to `BulkActionBar`
- Archive button: icon `archive_outlined`, removes senders from local DB after archiving
- Mark as Read button: icon `mark_email_read_outlined`, keeps senders in tree (just updates read state)
- Add confirmation dialogs for both actions matching existing delete dialog pattern

**Files:**
- `lib/core/services/gmail_service.dart` (add archive and mark-as-read methods)
- `lib/features/sender_analysis/widgets/bulk_action_bar.dart` (add buttons and dialogs)

---

### Task 7: Statistics Dashboard
Add a stats view showing inbox analytics using existing DAO queries.

**Changes:**
- Add `deletedEmailCount` integer column to `SyncStateTable` (default 0)
- Regenerate Drift code after schema change
- Increment `deletedEmailCount` in `SyncStateDao` when bulk delete completes
- Create `features/statistics/` feature directory with providers/, screens/, widgets/
- Create `StatsProvider` that queries: total senders, total emails, emails per category (group by on sender_table), top 10 senders by email count, deleted email count from sync_state
- Create `StatsScreen` with card-based layout: summary cards at top (total emails, total senders, emails deleted), category breakdown list, top senders list
- Add stats navigation (tab or button) to home screen
- No charts — text and cards only

**Files:**
- `lib/core/database/tables/sync_state_table.dart` (add column)
- `lib/core/database/daos/sync_state_dao.dart` (add increment method)
- `lib/core/database/database.dart` (regenerate)
- `lib/core/database/database.g.dart` (regenerate)
- `lib/features/statistics/providers/stats_provider.dart` (new)
- `lib/features/statistics/screens/stats_screen.dart` (new)
- `lib/features/statistics/widgets/stat_card.dart` (new)
- `lib/features/statistics/widgets/category_breakdown.dart` (new)
- `lib/features/statistics/widgets/top_senders_list.dart` (new)
- `lib/features/auth/screens/home_screen.dart` (add stats navigation)

---

### Task 8: Keyboard Shortcuts
Add keyboard shortcuts for power users using Flutter's Shortcuts/Actions system.

**Changes:**
- Create `shared/widgets/keyboard_shortcut_handler.dart` — wraps child with `Shortcuts` and `Actions` widgets
- Implement shortcuts:
  - `Cmd+A` — select all visible senders
  - `Delete` / `Backspace` — trigger delete for selected senders (opens confirmation dialog)
  - `Cmd+F` — focus search field (use `FocusNode` on search bar)
  - `Escape` — clear selection
  - `Cmd+?` — show help overlay with shortcut list
- Create `shared/widgets/shortcut_help_overlay.dart` — modal listing all shortcuts
- Wrap `HomeScreen` with `KeyboardShortcutHandler`
- Pass required callbacks/refs via provider or constructor

**Files:**
- `lib/shared/widgets/keyboard_shortcut_handler.dart` (new)
- `lib/shared/widgets/shortcut_help_overlay.dart` (new)
- `lib/features/auth/screens/home_screen.dart` (wrap with handler)
- `lib/features/sender_analysis/widgets/sender_search_bar.dart` (expose FocusNode)

---

### Task 9: Integration Testing & Polish
End-to-end testing of all Phase 2 features and UI polish.

**Changes:**
- Test keychain migration: verify old file tokens migrate correctly, old file is deleted
- Test category engine: verify all 5 layers categorize correctly, re-categorization updates existing senders
- Test category filtering: verify filter composes with search and unsubscribe filter
- Test Newsletter Nuke Mode: verify only newsletters with unsubscribe links shown
- Test bulk archive and mark-as-read: verify Gmail API calls and local DB updates
- Test stats dashboard: verify counts match, deleted count increments after bulk delete
- Test keyboard shortcuts: verify all 5 shortcuts work correctly
- Polish: consistent spacing, loading states, error handling for new features
- Verify dark mode for all new UI components

**Files:**
- `test/` directory (new and updated test files)
- Various UI files (minor polish adjustments)

---

## Dependency Graph

```
1 (Save Docs)
2 (Keychain) — independent
3 (Wire CategoryEngine) — independent
4 (Color Coding) → depends on 3
5 (Category Filtering) → depends on 3, 4
6 (Bulk Actions) — independent
7 (Statistics) → depends on 6 (needs deleted count from bulk delete tracking)
8 (Keyboard Shortcuts) → depends on 5, 6 (needs filter/action providers to exist)
9 (Testing & Polish) → depends on all above (2-8)
```

**Parallelizable:** Tasks 2, 3, and 6 can run in parallel after Task 1.

## Files Summary

### New Files
- `lib/features/statistics/providers/stats_provider.dart`
- `lib/features/statistics/screens/stats_screen.dart`
- `lib/features/statistics/widgets/stat_card.dart`
- `lib/features/statistics/widgets/category_breakdown.dart`
- `lib/features/statistics/widgets/top_senders_list.dart`
- `lib/shared/widgets/keyboard_shortcut_handler.dart`
- `lib/shared/widgets/shortcut_help_overlay.dart`

### Modified Files
- `pubspec.yaml`
- `lib/core/services/token_storage.dart`
- `lib/core/services/gmail_service.dart`
- `lib/core/database/tables/sync_state_table.dart`
- `lib/core/database/daos/sender_dao.dart`
- `lib/core/database/daos/sync_state_dao.dart`
- `lib/core/database/database.dart` + `.g.dart`
- `lib/features/sender_analysis/providers/sender_providers.dart`
- `lib/features/sender_analysis/screens/sender_panel.dart`
- `lib/features/sender_analysis/widgets/sender_tile.dart`
- `lib/features/sender_analysis/widgets/sender_search_bar.dart`
- `lib/features/sender_analysis/widgets/bulk_action_bar.dart`
- `lib/features/auth/screens/home_screen.dart`
- `lib/features/sync/providers/sync_provider.dart`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

## Verification Checklist

- [ ] Keychain storage works: tokens read/write via flutter_secure_storage
- [ ] Migration works: old file tokens migrate to keychain, old file deleted
- [ ] App launches without code signing in debug (keychain may require signing — verify fallback)
- [ ] All senders have categories after re-categorization runs
- [ ] Category colors display on sender tiles in both light and dark themes
- [ ] Category filter dropdown filters sender tree correctly
- [ ] Category filter composes with search query and unsubscribe filter
- [ ] Newsletter Nuke Mode shows only newsletters with unsubscribe links
- [ ] Archive bulk action removes INBOX label via Gmail API
- [ ] Mark as Read bulk action removes UNREAD label via Gmail API
- [ ] Archived senders removed from local DB
- [ ] Stats dashboard shows correct totals
- [ ] Deleted email count increments after bulk delete
- [ ] Cmd+A selects all visible senders
- [ ] Delete key opens confirmation dialog for selected senders
- [ ] Cmd+F focuses search field
- [ ] Escape clears selection
- [ ] Cmd+? shows help overlay
- [ ] No regressions in Phase 1 features (sync, delete, unsubscribe, search, sort)
