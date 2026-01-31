import 'email_category.dart';

class Sender {
  final String email;
  final String? displayName;
  final String domain;
  final int emailCount;
  final DateTime mostRecent;
  final EmailCategory category;
  final String? unsubscribeLink;

  const Sender({
    required this.email,
    this.displayName,
    required this.domain,
    required this.emailCount,
    required this.mostRecent,
    required this.category,
    this.unsubscribeLink,
  });

  Sender copyWith({
    String? email,
    String? displayName,
    String? domain,
    int? emailCount,
    DateTime? mostRecent,
    EmailCategory? category,
    String? unsubscribeLink,
  }) {
    return Sender(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      domain: domain ?? this.domain,
      emailCount: emailCount ?? this.emailCount,
      mostRecent: mostRecent ?? this.mostRecent,
      category: category ?? this.category,
      unsubscribeLink: unsubscribeLink ?? this.unsubscribeLink,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sender &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;

  @override
  String toString() => 'Sender($email, count: $emailCount)';
}
