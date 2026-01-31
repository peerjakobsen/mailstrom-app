import '../../../core/database/database.dart';

class SenderGroup {
  final String domain;
  final List<SenderTableData> senders;

  const SenderGroup({required this.domain, required this.senders});

  int get totalEmails =>
      senders.fold(0, (sum, s) => sum + s.emailCount);
}
