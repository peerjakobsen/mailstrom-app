## Dart data models

- **Immutable Models**: Use `@immutable` annotation or `freezed` package for data classes; prefer `final` fields
- **Factory Constructors**: Provide `fromJson` and `fromGmailMessage` factory constructors for parsing API and storage data
- **toJson / toMap**: Implement serialization methods for SQLite storage
- **Equatable**: Implement `==` and `hashCode` (or use `freezed`/`equatable`) for reliable state comparison in Riverpod
- **Null Safety**: Model optional fields with nullable types (`String?`); avoid default empty strings as null stand-ins
- **Enums for Categories**: Use Dart enums (e.g., `EmailCategory`) with extension methods for display names and icons
- **Separation of Concerns**: Keep data models free of UI logic and business rules; models are pure data containers
- **CopyWith**: Provide `copyWith` methods for creating modified copies of immutable models
