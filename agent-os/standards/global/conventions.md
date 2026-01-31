## Flutter project conventions

- **Consistent Project Structure**: Organize by feature (e.g., `lib/features/auth/`, `lib/features/sender_tree/`) with shared code in `lib/core/` and `lib/shared/`
- **One Widget Per File**: Keep each widget in its own file; name the file to match the widget class in snake_case
- **Barrel Exports**: Use barrel files sparingly and only for public API surfaces of a feature module
- **Environment Configuration**: Store OAuth client IDs and API keys in environment config or dart-define; never commit secrets to version control
- **Dependency Management**: Keep pubspec.yaml dependencies minimal and up-to-date; document why non-obvious dependencies are used
- **Version Control Best Practices**: Use clear commit messages, feature branches, and meaningful pull requests with descriptions
- **Code Review Process**: Establish a consistent code review process with clear expectations for reviewers and authors
- **Platform Channels**: Isolate platform-specific code (macOS Keychain, native title bar) behind clean Dart interfaces
- **Asset Management**: Store images, fonts, and other assets in the `assets/` directory and declare them in pubspec.yaml
