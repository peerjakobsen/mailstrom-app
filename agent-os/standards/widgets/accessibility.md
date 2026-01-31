## Flutter accessibility

- **Semantics Widget**: Use `Semantics` to provide labels, hints, and roles for custom widgets that aren't inherently accessible
- **Keyboard Navigation**: Ensure all interactive elements are reachable and operable via keyboard (Tab, Enter, Escape, arrow keys)
- **Focus Management**: Use `FocusNode` and `FocusTraversalGroup` to control focus order in complex layouts like the master-detail view
- **Sufficient Contrast**: Maintain 4.5:1 contrast ratio for text; verify in both light and dark themes
- **Meaningful Labels**: Provide `tooltip` on `IconButton` widgets and `semanticsLabel` on `Text` for icon-only buttons
- **VoiceOver Testing**: Test the app with macOS VoiceOver enabled to verify screen reader compatibility
- **Exclude Decorative Elements**: Use `ExcludeSemantics` or `Semantics(excludeSemantics: true)` for purely decorative widgets
- **Large Hit Targets**: Keep interactive elements at least 44x44 logical pixels for comfortable interaction
