import 'package:flutter_test/flutter_test.dart';
import 'package:mailstrom/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('allows requests within capacity', () async {
      final limiter = RateLimiter(unitsPerSecond: 100);
      // Should not throw or block significantly
      await limiter.acquire(5);
      await limiter.acquire(5);
      await limiter.acquire(5);
    });

    test('initial capacity equals unitsPerSecond', () async {
      final limiter = RateLimiter(unitsPerSecond: 10);
      // Should be able to acquire up to 10 units immediately
      await limiter.acquire(10);
    });
  });
}
