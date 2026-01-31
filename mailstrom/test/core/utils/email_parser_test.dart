import 'package:flutter_test/flutter_test.dart';
import 'package:mailstrom/core/utils/email_parser.dart';

void main() {
  group('EmailParser.parseFromHeader', () {
    test('parses name and email in angle brackets', () {
      final (name, email) =
          EmailParser.parseFromHeader('John Doe <john@example.com>');
      expect(name, 'John Doe');
      expect(email, 'john@example.com');
    });

    test('parses quoted name and email', () {
      final (name, email) =
          EmailParser.parseFromHeader('"Jane Smith" <jane@test.org>');
      expect(name, 'Jane Smith');
      expect(email, 'jane@test.org');
    });

    test('parses plain email address', () {
      final (name, email) =
          EmailParser.parseFromHeader('user@domain.com');
      expect(name, isNull);
      expect(email, 'user@domain.com');
    });

    test('parses email with no display name', () {
      final (name, email) =
          EmailParser.parseFromHeader('<noreply@company.com>');
      expect(name, isNull);
      expect(email, 'noreply@company.com');
    });

    test('handles empty name in angle brackets', () {
      final (name, email) =
          EmailParser.parseFromHeader(' <test@example.com>');
      expect(name, isNull);
      expect(email, 'test@example.com');
    });
  });
}
