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
      expect(EmailCategory.automated.displayName, 'Automated');
      expect(EmailCategory.unknown.displayName, 'Unknown');
    });

    test('has 8 values', () {
      expect(EmailCategory.values.length, 8);
    });

    test('fromString returns correct category', () {
      expect(EmailCategory.fromString('personal'), EmailCategory.personal);
      expect(EmailCategory.fromString('automated'), EmailCategory.automated);
      expect(EmailCategory.fromString('unknown'), EmailCategory.unknown);
      expect(EmailCategory.fromString('invalid'), EmailCategory.unknown);
    });
  });
}
