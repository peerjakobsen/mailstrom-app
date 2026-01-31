import 'package:googleapis/gmail/v1.dart';

class ParsedEmail {
  final String messageId;
  final String senderEmail;
  final String? senderName;
  final String domain;
  final String subject;
  final DateTime date;
  final String snippet;
  final bool isRead;
  final String? unsubscribeLink;
  final String? category;

  const ParsedEmail({
    required this.messageId,
    required this.senderEmail,
    this.senderName,
    required this.domain,
    required this.subject,
    required this.date,
    required this.snippet,
    required this.isRead,
    this.unsubscribeLink,
    this.category,
  });
}

class EmailParser {
  static ParsedEmail? parseMessage(Message message) {
    if (message.id == null) return null;

    final headers = message.payload?.headers ?? [];
    final fromHeader = _getHeader(headers, 'From');
    if (fromHeader == null) return null;

    final (name, email) = parseFromHeader(fromHeader);
    if (email.isEmpty) return null;

    final domain = email.contains('@') ? email.split('@').last : email;

    final date = _parseInternalDate(message.internalDate) ?? DateTime.now();

    final subject = _getHeader(headers, 'Subject') ?? '(no subject)';
    final snippet = message.snippet ?? '';

    final isRead = !(message.labelIds?.contains('UNREAD') ?? false);

    final unsubscribeHeader = _getHeader(headers, 'List-Unsubscribe');
    final unsubscribeLink = _parseUnsubscribeLink(unsubscribeHeader);

    final category = _categorize(message.labelIds, unsubscribeHeader);

    return ParsedEmail(
      messageId: message.id!,
      senderEmail: email.toLowerCase(),
      senderName: name,
      domain: domain.toLowerCase(),
      subject: subject,
      date: date,
      snippet: snippet,
      isRead: isRead,
      unsubscribeLink: unsubscribeLink,
      category: category,
    );
  }

  static (String?, String) parseFromHeader(String from) {
    // Handle: "Display Name <email@domain.com>"
    final match = RegExp(r'"?([^"<]*)"?\s*<([^>]+)>').firstMatch(from);
    if (match != null) {
      final name = match.group(1)?.trim();
      final email = match.group(2)?.trim() ?? '';
      return (name?.isEmpty == true ? null : name, email);
    }
    // Handle: plain email
    return (null, from.trim());
  }

  static String? _getHeader(
    List<MessagePartHeader> headers,
    String name,
  ) {
    for (final header in headers) {
      if (header.name?.toLowerCase() == name.toLowerCase()) {
        return header.value;
      }
    }
    return null;
  }

  static DateTime? _parseInternalDate(String? internalDate) {
    if (internalDate == null) return null;
    final ms = int.tryParse(internalDate);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static String? _parseUnsubscribeLink(String? header) {
    if (header == null) return null;

    // Prefer https links over mailto
    final httpMatch = RegExp(r'<(https?://[^>]+)>').firstMatch(header);
    if (httpMatch != null) return httpMatch.group(1);

    final mailtoMatch = RegExp(r'<(mailto:[^>]+)>').firstMatch(header);
    if (mailtoMatch != null) return mailtoMatch.group(1);

    return null;
  }

  static String _categorize(
    List<String>? labelIds,
    String? unsubscribeHeader,
  ) {
    if (labelIds == null) return 'unknown';

    if (labelIds.contains('CATEGORY_SOCIAL')) return 'social';
    if (labelIds.contains('CATEGORY_PROMOTIONS')) return 'marketing';
    if (labelIds.contains('CATEGORY_UPDATES')) return 'notification';
    if (labelIds.contains('CATEGORY_FORUMS')) return 'social';

    if (unsubscribeHeader != null) return 'newsletter';

    if (labelIds.contains('CATEGORY_PERSONAL')) return 'personal';

    return 'unknown';
  }
}
