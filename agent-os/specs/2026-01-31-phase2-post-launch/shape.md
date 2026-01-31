# Phase 2: Post-Launch Features — Shape

## Problem
After MVP launch, Mailstrom needs deeper intelligence and polish:
- Categorization relies solely on Gmail labels, missing many senders
- No way to filter senders by category type
- No statistics or analytics about inbox health
- Tokens stored in plain-text file instead of OS keychain
- Only bulk delete available (no archive or mark-as-read)
- No keyboard shortcuts for power users

## Solution
Six features that add smart categorization, filtering, analytics, security, more bulk actions, and keyboard shortcuts.

## Features
1. **Smart Categorization Engine** — Rule-based heuristics using sender domain, address patterns, subject keywords, and unsubscribe headers alongside existing Gmail labels
2. **Keychain Token Storage** — Migrate from file-based storage to macOS Keychain via flutter_secure_storage with automatic migration
3. **Category Filtering** — Filter sender tree by category with dedicated Newsletter Nuke Mode
4. **Statistics Dashboard** — Inbox analytics: total emails, senders, space reclaimed, category breakdown, top senders
5. **Additional Bulk Actions** — Archive (remove INBOX label) and Mark as Read (remove UNREAD label)
6. **Keyboard Shortcuts** — Cmd+A select all, Delete trash selected, Cmd+F focus search, Cmd+? help overlay, Escape clear selection

## Scope

### IN
- New `automated` category for bots, CI, system emails
- Rule-based categorization engine with 5-layer heuristic
- One-time re-categorization of existing senders on upgrade
- Category color coding on sender tiles
- Newsletter Nuke Mode toggle
- Text/card-based stats dashboard (no charts)
- Keychain migration with old-file cleanup
- Code signing setup guide
- Cmd+A, Delete, Escape, Cmd+F, Cmd+? shortcuts

### OUT
- ML-based classification
- User-editable rules or custom categories
- Chart/graph visualizations
- Per-email categorization (stays sender-level)
- Windows/Linux keychain equivalents
- Undo for bulk actions

## Decisions
- Category filter is additive to existing unsubscribe filter (they compose)
- Stats use existing DAO queries, no separate analytics tables
- Keychain migration is transparent — read old file, write to keychain, delete file
- Newsletter Nuke Mode = category filter to newsletter + hide senders without unsubscribe links
- Archive/mark-as-read use Gmail API `messages.modify` (add/remove labels)
- Deleted email count tracked in sync_state for stats
