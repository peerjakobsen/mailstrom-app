import 'package:flutter_test/flutter_test.dart';
import 'package:mailstrom/core/utils/unsubscribe_parser.dart';

void main() {
  group('UnsubscribeParser.fromHeader', () {
    test('extracts https link', () {
      final result = UnsubscribeParser.fromHeader(
        '<https://example.com/unsubscribe?id=123>',
      );
      expect(result, 'https://example.com/unsubscribe?id=123');
    });

    test('prefers https over mailto', () {
      final result = UnsubscribeParser.fromHeader(
        '<mailto:unsub@example.com>, <https://example.com/unsub>',
      );
      expect(result, 'https://example.com/unsub');
    });

    test('falls back to mailto', () {
      final result = UnsubscribeParser.fromHeader(
        '<mailto:unsubscribe@list.example.com>',
      );
      expect(result, 'mailto:unsubscribe@list.example.com');
    });

    test('returns null for empty header', () {
      expect(UnsubscribeParser.fromHeader(null), isNull);
      expect(UnsubscribeParser.fromHeader(''), isNull);
    });

    test('extracts http link', () {
      final result = UnsubscribeParser.fromHeader(
        '<http://legacy.example.com/unsub>',
      );
      expect(result, 'http://legacy.example.com/unsub');
    });
  });

  group('UnsubscribeParser.fromBody', () {
    test('finds unsubscribe URL in body', () {
      final result = UnsubscribeParser.fromBody(
        'Click here to unsubscribe: https://example.com/unsubscribe?token=abc',
      );
      expect(result, contains('unsubscribe'));
    });

    test('finds opt-out URL', () {
      final result = UnsubscribeParser.fromBody(
        'To opt out visit https://example.com/opt-out',
      );
      expect(result, contains('opt-out'));
    });

    test('returns null when no link found', () {
      expect(
        UnsubscribeParser.fromBody('Hello, this is a normal email.'),
        isNull,
      );
    });

    test('returns null for null body', () {
      expect(UnsubscribeParser.fromBody(null), isNull);
    });
  });

  group('UnsubscribeParser.extract', () {
    test('prefers header over body', () {
      final result = UnsubscribeParser.extract(
        header: '<https://header-link.com/unsub>',
        bodyText: 'https://body-link.com/unsubscribe',
      );
      expect(result, 'https://header-link.com/unsub');
    });

    test('falls back to body when header empty', () {
      final result = UnsubscribeParser.extract(
        header: null,
        bodyText: 'Visit https://example.com/unsubscribe to stop emails',
      );
      expect(result, contains('unsubscribe'));
    });
  });
}
