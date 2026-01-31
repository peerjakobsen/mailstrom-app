## Input validation in Flutter

- **Validate at Boundaries**: Validate data at entry points -- user input, API responses, and local storage reads
- **Gmail API Response Validation**: Verify expected fields exist in API responses before parsing; handle malformed data gracefully
- **Null-Safe Parsing**: Use null-aware operators and default values when parsing JSON from the Gmail API
- **Type-Safe Models**: Use strongly-typed Dart model classes (with `fromJson`/`toJson`) rather than raw Maps
- **Form Validation**: Use Flutter's `Form` and `TextFormField` validators for any user input (e.g., search filters, date ranges)
- **Specific Error Messages**: Provide clear, field-specific feedback when validation fails
- **Sanitize Display Data**: Sanitize email content before rendering to prevent rendering issues or injection in WebView/HTML widgets
