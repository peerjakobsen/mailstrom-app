class EmailSummary {
  final String id;
  final String senderEmail;
  final String subject;
  final DateTime date;
  final String snippet;
  final bool isRead;
  final String? unsubscribeLink;

  const EmailSummary({
    required this.id,
    required this.senderEmail,
    required this.subject,
    required this.date,
    required this.snippet,
    required this.isRead,
    this.unsubscribeLink,
  });

  EmailSummary copyWith({
    String? id,
    String? senderEmail,
    String? subject,
    DateTime? date,
    String? snippet,
    bool? isRead,
    String? unsubscribeLink,
  }) {
    return EmailSummary(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      snippet: snippet ?? this.snippet,
      isRead: isRead ?? this.isRead,
      unsubscribeLink: unsubscribeLink ?? this.unsubscribeLink,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmailSummary($id, $subject)';
}
