## Flutter widget best practices

- **Single Responsibility**: Each widget should have one clear purpose; break complex UIs into smaller widget compositions
- **Stateless by Default**: Prefer `StatelessWidget` when no local mutable state is needed; use `ConsumerWidget` for Riverpod integration
- **Extract Build Methods**: If a `build()` method exceeds ~50 lines, extract sub-widgets into separate classes (not private methods) for rebuild optimization
- **Const Constructors**: Use `const` constructors on widgets and pass `const` children wherever possible to avoid unnecessary rebuilds
- **Keys**: Use `ValueKey` or `ObjectKey` on list items and widgets that move within the tree; avoid `UniqueKey` unless intentionally forcing rebuilds
- **Composition Over Inheritance**: Build complex widgets by composing smaller ones, not by extending widget classes
- **Minimal Props**: Keep constructor parameters manageable; if a widget needs many parameters, consider breaking it into composed sub-widgets
- **Consistent Naming**: Suffix widgets with their purpose (e.g., `SenderTreeView`, `EmailPreviewCard`, `BulkActionBar`)
- **Encapsulate State**: Keep state as local as possible; use Riverpod providers only when state is shared across widgets
