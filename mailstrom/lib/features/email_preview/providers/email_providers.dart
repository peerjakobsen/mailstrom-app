import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart';

import '../../../core/database/database.dart';
import '../../../core/services/gmail_service.dart';

final emailListProvider =
    StreamProvider.family<List<EmailSummaryTableData>, String>(
  (ref, senderEmail) {
    return ref.watch(emailDaoProvider).watchEmailsBySender(senderEmail);
  },
);

final selectedEmailIdProvider = StateProvider<String?>((ref) => null);

final fullEmailProvider =
    FutureProvider.family<EmailContent?, String>((ref, messageId) async {
  final gmailService = ref.read(gmailServiceProvider);
  final message = await gmailService.getFullMessage(messageId);
  return EmailContent.fromMessage(message);
});

class EmailContent {
  final String id;
  final String subject;
  final String from;
  final DateTime date;
  final String bodyText;
  final String? bodyHtml;
  final String? unsubscribeLink;

  const EmailContent({
    required this.id,
    required this.subject,
    required this.from,
    required this.date,
    required this.bodyText,
    this.bodyHtml,
    this.unsubscribeLink,
  });

  static EmailContent? fromMessage(Message message) {
    if (message.id == null) return null;

    final headers = message.payload?.headers ?? [];
    final subject = _header(headers, 'Subject') ?? '(no subject)';
    final from = _header(headers, 'From') ?? 'Unknown';
    final date = _parseInternalDate(message.internalDate) ?? DateTime.now();
    final unsubscribe = _header(headers, 'List-Unsubscribe');

    String bodyText = '';
    String? bodyHtml;

    _extractBody(message.payload, (text, html) {
      bodyText = text;
      bodyHtml = html;
    });

    return EmailContent(
      id: message.id!,
      subject: subject,
      from: from,
      date: date,
      bodyText: bodyText,
      bodyHtml: bodyHtml,
      unsubscribeLink: unsubscribe,
    );
  }

  static DateTime? _parseInternalDate(String? internalDate) {
    if (internalDate == null) return null;
    final ms = int.tryParse(internalDate);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static String? _header(List<MessagePartHeader> headers, String name) {
    for (final h in headers) {
      if (h.name?.toLowerCase() == name.toLowerCase()) return h.value;
    }
    return null;
  }

  static void _extractBody(
    MessagePart? part,
    void Function(String text, String? html) callback,
  ) {
    if (part == null) {
      callback('', null);
      return;
    }

    String? text;
    String? html;

    if (part.mimeType == 'text/plain' && part.body?.data != null) {
      text = _decodeBase64(part.body!.data!);
    } else if (part.mimeType == 'text/html' && part.body?.data != null) {
      html = _decodeBase64(part.body!.data!);
    }

    if (part.parts != null) {
      for (final subPart in part.parts!) {
        if (subPart.mimeType == 'text/plain' && subPart.body?.data != null) {
          text ??= _decodeBase64(subPart.body!.data!);
        }
        if (subPart.mimeType == 'text/html' && subPart.body?.data != null) {
          html ??= _decodeBase64(subPart.body!.data!);
        }
        if (subPart.parts != null) {
          _extractBody(subPart, (t, h) {
            text ??= t;
            html ??= h;
          });
        }
      }
    }

    callback(text ?? html ?? '', html);
  }

  static String _decodeBase64(String data) {
    // Gmail uses URL-safe base64 encoding
    final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
    try {
      return utf8.decode(base64.decode(normalized));
    } catch (_) {
      return data;
    }
  }
}
