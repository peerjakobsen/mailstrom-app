class UnsubscribeParser {
  /// Extract HTTP(S) unsubscribe link from List-Unsubscribe header.
  /// Only returns browser-openable URLs; mailto links are ignored.
  static String? fromHeader(String? header) {
    if (header == null || header.isEmpty) return null;

    final httpMatch = RegExp(r'<(https?://[^>]+)>').firstMatch(header);
    if (httpMatch != null) return httpMatch.group(1);

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

  /// Try HTTP link from header, then fall back to body scan.
  static String? extract({String? header, String? bodyText}) {
    return fromHeader(header) ?? fromBody(bodyText);
  }
}
