## Dart coding style

- **Follow Effective Dart**: Adhere to the official Effective Dart style guide for naming, formatting, and usage conventions
- **Naming Conventions**: Use lowerCamelCase for variables, functions, and parameters; UpperCamelCase for classes, enums, and typedefs; lowercase_with_underscores for libraries and file names
- **Prefer const**: Use `const` constructors and values wherever possible for compile-time constants and widget optimization
- **Prefer final**: Use `final` for variables that are assigned once; avoid `var` when the type or finality can be explicit
- **Type Annotations**: Annotate public API return types and parameters; omit types on local variables when the type is obvious from the assignment
- **Trailing Commas**: Use trailing commas in argument lists, parameter lists, and collection literals to get cleaner diffs and auto-formatting
- **Small, Focused Functions**: Keep functions small and focused on a single task for better readability and testability
- **Remove Dead Code**: Delete unused code, commented-out blocks, and imports rather than leaving them as clutter
- **Backward Compatibility Only When Required**: Unless specifically instructed otherwise, do not write additional logic to handle backward compatibility
- **DRY Principle**: Extract repeated logic into reusable functions, mixins, or extension methods
- **Avoid Dynamic**: Prefer typed code over `dynamic`; use generics when flexibility is needed
- **Use Null Safety**: Leverage Dart's sound null safety; avoid unnecessary null assertions (`!`) and prefer null-aware operators (`?.`, `??`)
