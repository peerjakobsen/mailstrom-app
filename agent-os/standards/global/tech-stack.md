## Tech Stack

### Framework & Runtime
- **Application Framework:** Flutter 3.x
- **Language:** Dart
- **Design System:** Material 3
- **Platform:** macOS desktop (future: Windows, Linux)

### State Management
- **State Management:** Riverpod (flutter_riverpod)
- **Pattern:** Provider-based with StateNotifier/AsyncNotifier for complex state

### Local Storage
- **Database:** SQLite (via drift or sqflite)
- **Secure Storage:** flutter_secure_storage (macOS Keychain)
- **Use Case:** Cache sender analysis, email metadata, user preferences

### API Integration
- **Gmail API:** googleapis, googleapis_auth packages
- **Authentication:** Google OAuth 2.0
- **Scopes:** gmail.readonly, gmail.modify, gmail.labels

### Testing & Quality
- **Test Framework:** flutter_test, integration_test
- **Linting:** flutter_lints (analysis_options.yaml)
- **Formatting:** dart format (2-space indentation)

### Build & Tooling
- **Package Manager:** pub (pubspec.yaml)
- **Build System:** Flutter build system
- **IDE:** VS Code or Android Studio with Flutter/Dart plugins
