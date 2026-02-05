import '../../../core/database/database.dart';

class SenderGroup {
  final String domain;
  final List<SenderTableData> senders;

  const SenderGroup({required this.domain, required this.senders});

  int get totalEmails =>
      senders.fold(0, (sum, s) => sum + s.emailCount);

  DateTime? get mostRecentDate {
    if (senders.isEmpty) return null;
    return senders.map((s) => s.mostRecent).reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
  }
}
