import 'package:flutter/material.dart';

enum EmailCategory {
  personal('Personal'),
  social('Social'),
  newsletter('Newsletter'),
  notification('Notification'),
  marketing('Marketing'),
  transactional('Transactional'),
  automated('Automated'),
  unknown('Unknown');

  const EmailCategory(this.displayName);
  final String displayName;

  Color get color => switch (this) {
    personal => const Color(0xFF4285F4),
    social => const Color(0xFF34A853),
    newsletter => const Color(0xFFFBBC05),
    notification => const Color(0xFF9C27B0),
    marketing => const Color(0xFFEA4335),
    transactional => const Color(0xFF00ACC1),
    automated => const Color(0xFF78909C),
    unknown => const Color(0xFFBDBDBD),
  };

  static EmailCategory fromString(String value) {
    return EmailCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EmailCategory.unknown,
    );
  }
}
