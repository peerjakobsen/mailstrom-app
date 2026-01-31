import 'package:flutter_test/flutter_test.dart';
import 'package:mailstrom/core/models/email_category.dart';

void main() {
  group('EmailCategory', () {
    test('has correct display names', () {
      expect(EmailCategory.personal.displayName, 'Personal');
      expect(EmailCategory.social.displayName, 'Social');
      expect(EmailCategory.newsletter.displayName, 'Newsletter');
      expect(EmailCategory.notification.displayName, 'Notification');
      expect(EmailCategory.marketing.displayName, 'Marketing');
      expect(EmailCategory.transactional.displayName, 'Transactional');
      expect(EmailCategory.unknown.displayName, 'Unknown');
    });

    test('has 7 values', () {
      expect(EmailCategory.values.length, 7);
    });
  });
}
