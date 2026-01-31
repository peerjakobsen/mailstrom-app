import 'package:flutter_test/flutter_test.dart';
import 'package:mailstrom/core/utils/category_engine.dart';

void main() {
  group('CategoryEngine.categorize', () {
    // Layer 1: Gmail labels
    test('returns social for CATEGORY_SOCIAL label', () {
      expect(
        CategoryEngine.categorize(
          labelIds: ['CATEGORY_SOCIAL'],
          senderEmail: 'test@example.com',
          domain: 'example.com',
          subject: 'Hello',
        ),
        'social',
      );
    });

    test('returns marketing for CATEGORY_PROMOTIONS label', () {
      expect(
        CategoryEngine.categorize(
          labelIds: ['CATEGORY_PROMOTIONS'],
          senderEmail: 'test@example.com',
          domain: 'example.com',
          subject: 'Sale!',
        ),
        'marketing',
      );
    });

    test('returns notification for CATEGORY_UPDATES label', () {
      expect(
        CategoryEngine.categorize(
          labelIds: ['CATEGORY_UPDATES'],
          senderEmail: 'test@example.com',
          domain: 'example.com',
          subject: 'Update',
        ),
        'notification',
      );
    });

    test('returns personal for CATEGORY_PERSONAL label', () {
      expect(
        CategoryEngine.categorize(
          labelIds: ['CATEGORY_PERSONAL'],
          senderEmail: 'friend@example.com',
          domain: 'example.com',
          subject: 'Hey',
        ),
        'personal',
      );
    });

    // Labels take priority over domain
    test('Gmail label overrides domain match', () {
      expect(
        CategoryEngine.categorize(
          labelIds: ['CATEGORY_SOCIAL'],
          senderEmail: 'noreply@github.com',
          domain: 'github.com',
          subject: 'Build failed',
        ),
        'social',
      );
    });

    // Layer 2: Known sender domains
    test('returns newsletter for substack.com domain', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'author@substack.com',
          domain: 'substack.com',
          subject: 'Weekly digest',
        ),
        'newsletter',
      );
    });

    test('returns automated for github.com domain', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'notifications@github.com',
          domain: 'github.com',
          subject: 'New issue',
        ),
        'automated',
      );
    });

    test('returns social for facebookmail.com domain', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'notification@facebookmail.com',
          domain: 'facebookmail.com',
          subject: 'New friend request',
        ),
        'social',
      );
    });

    test('returns transactional for paypal.com domain', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'service@paypal.com',
          domain: 'paypal.com',
          subject: 'Payment received',
        ),
        'transactional',
      );
    });

    test('returns marketing for hubspot.com domain', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'marketing@hubspot.com',
          domain: 'hubspot.com',
          subject: 'New features',
        ),
        'marketing',
      );
    });

    // Layer 3: Sender address patterns
    test('returns automated for noreply@ address', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'noreply@example.com',
          domain: 'example.com',
          subject: 'Notification',
        ),
        'automated',
      );
    });

    test('returns automated for no-reply@ address', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'no-reply@example.com',
          domain: 'example.com',
          subject: 'Alert',
        ),
        'automated',
      );
    });

    test('returns transactional for billing@ address', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'billing@example.com',
          domain: 'example.com',
          subject: 'Monthly statement',
        ),
        'transactional',
      );
    });

    test('returns newsletter for newsletter@ address', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'newsletter@example.com',
          domain: 'example.com',
          subject: 'This week in tech',
        ),
        'newsletter',
      );
    });

    // Layer 4: Subject keyword matching
    test('returns transactional for receipt subject', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'store@shop.com',
          domain: 'shop.com',
          subject: 'Your receipt for order #1234',
        ),
        'transactional',
      );
    });

    test('returns automated for build failed subject', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'ci@mycompany.com',
          domain: 'mycompany.com',
          subject: 'Build failed for main branch',
        ),
        'automated',
      );
    });

    test('returns notification for password reset subject', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'security@myapp.com',
          domain: 'myapp.com',
          subject: 'Password reset request',
        ),
        'notification',
      );
    });

    // Layer 5: Unsubscribe header fallback
    test('returns newsletter for unsubscribe header', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'info@random.com',
          domain: 'random.com',
          subject: 'Regular update',
          unsubscribeHeader: '<https://random.com/unsub>',
        ),
        'newsletter',
      );
    });

    // Fallback
    test('returns unknown when no signals match', () {
      expect(
        CategoryEngine.categorize(
          senderEmail: 'john@personal.com',
          domain: 'personal.com',
          subject: 'Hey there',
        ),
        'unknown',
      );
    });

    // Null labelIds
    test('handles null labelIds gracefully', () {
      expect(
        CategoryEngine.categorize(
          labelIds: null,
          senderEmail: 'john@personal.com',
          domain: 'personal.com',
          subject: 'Hello',
        ),
        'unknown',
      );
    });
  });
}
