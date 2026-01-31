/// Rule-based email categorization engine with layered heuristics.
///
/// Priority order:
/// 1. Gmail labels (highest — existing behavior)
/// 2. Known sender domain lists
/// 3. Sender address patterns (noreply@, billing@, etc.)
/// 4. Subject keyword matching
/// 5. Unsubscribe header presence (lowest — fallback)
class CategoryEngine {
  const CategoryEngine._();

  /// Categorize an email based on all available signals.
  static String categorize({
    List<String>? labelIds,
    required String senderEmail,
    required String domain,
    required String subject,
    String? unsubscribeHeader,
  }) {
    // Layer 1: Gmail labels (highest priority)
    final labelCategory = _fromLabels(labelIds);
    if (labelCategory != null) return labelCategory;

    // Layer 2: Known sender domains
    final domainCategory = _fromDomain(domain);
    if (domainCategory != null) return domainCategory;

    // Layer 3: Sender address patterns
    final patternCategory = _fromSenderPattern(senderEmail);
    if (patternCategory != null) return patternCategory;

    // Layer 4: Subject keyword matching
    final subjectCategory = _fromSubject(subject);
    if (subjectCategory != null) return subjectCategory;

    // Layer 5: Unsubscribe header (fallback)
    if (unsubscribeHeader != null) return 'newsletter';

    return 'unknown';
  }

  // -- Layer 1: Gmail labels --

  static String? _fromLabels(List<String>? labelIds) {
    if (labelIds == null) return null;

    if (labelIds.contains('CATEGORY_SOCIAL')) return 'social';
    if (labelIds.contains('CATEGORY_PROMOTIONS')) return 'marketing';
    if (labelIds.contains('CATEGORY_UPDATES')) return 'notification';
    if (labelIds.contains('CATEGORY_FORUMS')) return 'social';
    if (labelIds.contains('CATEGORY_PERSONAL')) return 'personal';

    return null;
  }

  // -- Layer 2: Known sender domains --

  static const _newsletterDomains = {
    'substack.com',
    'mailchimp.com',
    'campaign-archive.com',
    'list-manage.com',
    'convertkit.com',
    'beehiiv.com',
    'buttondown.email',
    'revue.email',
    'ghost.io',
    'tinyletter.com',
    'sendinblue.com',
    'brevo.com',
    'mailerlite.com',
    'getrevue.co',
  };

  static const _automatedDomains = {
    'github.com',
    'gitlab.com',
    'bitbucket.org',
    'circleci.com',
    'travis-ci.com',
    'app.codecov.io',
    'dependabot.com',
    'snyk.io',
    'sentry.io',
    'datadog.com',
    'pagerduty.com',
    'opsgenie.com',
    'vercel.com',
    'netlify.com',
    'heroku.com',
    'aws.amazon.com',
    'cloudflare.com',
    'digitalocean.com',
    'fly.io',
    'render.com',
    'railway.app',
    'codemagic.io',
  };

  static const _socialDomains = {
    'facebookmail.com',
    'linkedin.com',
    'twitter.com',
    'x.com',
    'instagram.com',
    'reddit.com',
    'discord.com',
    'slack.com',
    'meetup.com',
    'nextdoor.com',
    'tiktok.com',
    'mastodon.social',
    'threads.net',
    'bluesky.social',
  };

  static const _transactionalDomains = {
    'paypal.com',
    'stripe.com',
    'square.com',
    'shopify.com',
    'amazon.com',
    'uber.com',
    'lyft.com',
    'doordash.com',
    'grubhub.com',
    'instacart.com',
    'airbnb.com',
    'booking.com',
    'expedia.com',
  };

  static const _marketingDomains = {
    'constantcontact.com',
    'hubspot.com',
    'marketo.com',
    'salesforce.com',
    'pardot.com',
    'drip.com',
    'klaviyo.com',
    'activecampaign.com',
    'aweber.com',
    'getresponse.com',
    'moosend.com',
    'omnisend.com',
  };

  static String? _fromDomain(String domain) {
    final lower = domain.toLowerCase();

    if (_newsletterDomains.contains(lower)) return 'newsletter';
    if (_automatedDomains.contains(lower)) return 'automated';
    if (_socialDomains.contains(lower)) return 'social';
    if (_transactionalDomains.contains(lower)) return 'transactional';
    if (_marketingDomains.contains(lower)) return 'marketing';

    return null;
  }

  // -- Layer 3: Sender address patterns --

  static String? _fromSenderPattern(String email) {
    final local = email.split('@').first.toLowerCase();

    // Automated patterns
    const automatedPrefixes = [
      'noreply',
      'no-reply',
      'no_reply',
      'donotreply',
      'do-not-reply',
      'do_not_reply',
      'mailer-daemon',
      'postmaster',
      'system',
      'auto',
      'bot',
      'ci',
      'builds',
      'deploy',
      'alerts',
      'monitoring',
      'cron',
      'notifications',
    ];

    for (final prefix in automatedPrefixes) {
      if (local == prefix || local.startsWith('$prefix+') || local.startsWith('$prefix-')) {
        return 'automated';
      }
    }

    // Transactional patterns
    const transactionalPrefixes = [
      'billing',
      'invoice',
      'invoices',
      'receipt',
      'receipts',
      'orders',
      'order',
      'payment',
      'payments',
      'shipping',
      'delivery',
      'confirmation',
      'confirm',
      'account',
      'support',
    ];

    for (final prefix in transactionalPrefixes) {
      if (local == prefix || local.startsWith('$prefix+') || local.startsWith('$prefix-')) {
        return 'transactional';
      }
    }

    // Newsletter patterns
    const newsletterPrefixes = [
      'newsletter',
      'news',
      'digest',
      'weekly',
      'daily',
      'update',
      'updates',
    ];

    for (final prefix in newsletterPrefixes) {
      if (local == prefix || local.startsWith('$prefix+') || local.startsWith('$prefix-')) {
        return 'newsletter';
      }
    }

    return null;
  }

  // -- Layer 4: Subject keyword matching --

  static final _transactionalSubjectPatterns = RegExp(
    r'\b(receipt|invoice|order\s+confirm|shipping\s+confirm|payment\s+confirm'
    r'|your\s+order|shipped|delivered|tracking\s+number|refund|purchase)\b',
    caseSensitive: false,
  );

  static final _automatedSubjectPatterns = RegExp(
    r'\b(build\s+(failed|succeeded|passed)|pipeline|deploy|ci\/cd'
    r'|merge\s+request|pull\s+request|commit|security\s+alert'
    r'|vulnerability|cron|backup\s+(completed|failed)'
    r'|server\s+(down|up|alert)|incident|outage)\b',
    caseSensitive: false,
  );

  static final _notificationSubjectPatterns = RegExp(
    r'\b(password\s+reset|verify\s+your|confirm\s+your\s+email'
    r'|two-factor|2fa|login\s+attempt|sign[\s-]?in\s+alert'
    r'|security\s+code|verification\s+code)\b',
    caseSensitive: false,
  );

  static String? _fromSubject(String subject) {
    if (_transactionalSubjectPatterns.hasMatch(subject)) return 'transactional';
    if (_automatedSubjectPatterns.hasMatch(subject)) return 'automated';
    if (_notificationSubjectPatterns.hasMatch(subject)) return 'notification';

    return null;
  }
}
