## Material 3 theming

- **Use ThemeData**: Define light and dark themes using `ThemeData` with Material 3 color schemes (`ColorScheme.fromSeed`)
- **Respect System Theme**: Use `MediaQuery.platformBrightnessOf` or `ThemeMode.system` to follow macOS appearance settings
- **Design Tokens via Theme**: Access colors, typography, and spacing through `Theme.of(context)` rather than hardcoding values
- **Custom Color Scheme**: Extend `ColorScheme` with app-specific semantic colors (e.g., newsletter category, unsubscribe action) using `ThemeExtension`
- **Consistent Typography**: Use `TextTheme` roles (headlineMedium, bodyLarge, labelSmall) instead of ad-hoc text styles
- **Surface Tints and Elevation**: Use Material 3 surface tint and elevation system for visual hierarchy in the master-detail layout
- **macOS Native Feel**: Customize window title bar, toolbar styling, and spacing to feel native on macOS while using Material widgets
