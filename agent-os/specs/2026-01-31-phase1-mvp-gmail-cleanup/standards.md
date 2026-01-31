# Mailstrom Standards

## Tech Stack
- Framework: Flutter 3.x (macOS desktop)
- Language: Dart
- State Management: Riverpod (flutter_riverpod)
- Database: Drift (SQLite) with drift_dev for code generation
- API: Gmail API via googleapis package
- Auth: googleapis_auth (clientViaUserConsent)
- Secure Storage: flutter_secure_storage (macOS Keychain)
- Theme: Material 3

## Code Style
- 2 spaces for indentation
- snake_case for variables and methods
- PascalCase for classes
- UPPER_SNAKE_CASE for constants
- Single quotes for strings
- All models immutable with final fields
- Prefer composition over inheritance

## File Organization
- Feature-first directory structure
- Each feature has: providers/, screens/, widgets/, models/ (as needed)
- Core shared code in core/ and shared/
- One public class per file (private helpers OK)

## Dart/Flutter Conventions
- Use const constructors wherever possible
- Prefer final over var
- Use named parameters for constructors with 3+ params
- Use trailing commas for better formatting
- Explicit types for public APIs, inference OK for local vars

## State Management (Riverpod)
- AsyncNotifierProvider for complex async state
- StreamProvider for reactive DB queries
- StateProvider for simple UI state
- Provider for computed/derived state
- FutureProvider.family for parameterized queries

## Database (Drift)
- Tables defined in dedicated table files
- DAOs for each logical data group
- Reactive streams (watch*) for UI
- Transactions for batch operations
- Indexes on frequently queried columns
