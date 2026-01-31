## Flutter/Dart testing

- **Write Minimal Tests During Development**: Do not write tests for every change or intermediate step; complete the feature implementation first, then add strategic tests at logical completion points
- **Test Only Core User Flows**: Write tests for critical paths (OAuth flow, sender grouping logic, bulk delete) and primary user workflows; skip non-critical utilities until instructed
- **Defer Edge Case Testing**: Do not test edge cases or validation logic unless business-critical; address these in dedicated testing phases
- **Unit Test Business Logic**: Test Notifier classes, service methods, and model parsing independently from Flutter widgets
- **Widget Tests for Key Screens**: Use `WidgetTester` and `pumpWidget` for the main layout, sender tree, and bulk action bar
- **Mock External Services**: Use `mockito` or `mocktail` to mock `GmailService`, `SharedPreferences`, and database access in tests
- **Test Riverpod Providers**: Use `ProviderContainer` overrides to test providers in isolation with controlled dependencies
- **Clear Test Names**: Use descriptive names that explain the scenario and expected outcome
- **Fast Execution**: Keep unit tests fast; reserve integration tests for end-to-end flows
