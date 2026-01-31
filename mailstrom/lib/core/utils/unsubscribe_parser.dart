class UnsubscribeParser {
  /// Extract unsubscribe link from List-Unsubscribe header.
  /// Prefers https URLs over mailto links.
  static String? fromHeader(String? header) {
    if (header == null || header.isEmpty) return null;

    final httpMatch = RegExp(r'<(https?://[^>]+)>').firstMatch(header);
    if (httpMatch != null) return httpMatch.group(1);

    final mailtoMatch = RegExp(r'<(mailto:[^>]+)>').firstMatch(header);
    if (mailtoMatch != null) return mailtoMatch.group(1);

    return null;
  }

  /// Scan email body text for unsubscribe links.
  /// Fallback when List-Unsubscribe header is absent.
  static String? fromBody(String? bodyText) {
    if (bodyText == null || bodyText.isEmpty) return null;

    final patterns = [
      RegExp(r'https?://[^\s<>"]+unsubscribe[^\s<>"]*', caseSensitive: false),
      RegExp(r'https?://[^\s<>"]+opt.?out[^\s<>"]*', caseSensitive: false),
      RegExp(r'https?://[^\s<>"]+remove[^\s<>"]*', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(bodyText);
      if (match != null) return match.group(0);
    }

    return null;
  }

  /// Try HTTP link from header, then body, then mailto as last resort.
  static String? extract({String? header, String? bodyText}) {
    final headerLink = fromHeader(header);
    if (headerLink != null && !headerLink.startsWith('mailto:')) {
      return headerLink;
    }
    return fromBody(bodyText) ?? headerLink;
  }
}
