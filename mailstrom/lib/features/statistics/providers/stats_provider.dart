import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/email_category.dart';

class InboxStats {
  final int totalEmails;
  final int totalSenders;
  final int deletedEmails;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> topDomains;

  const InboxStats({
    required this.totalEmails,
    required this.totalSenders,
    required this.deletedEmails,
    required this.categoryBreakdown,
    required this.topDomains,
  });

  /// Category breakdown sorted by count descending, with display names.
  List<MapEntry<String, int>> get sortedCategories {
    final entries = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String categoryDisplayName(String key) {
    return EmailCategory.fromString(key).displayName;
  }
}

final inboxStatsProvider = FutureProvider<InboxStats>((ref) async {
  final senderDao = ref.watch(senderDaoProvider);
  final syncStateDao = ref.watch(syncStateDaoProvider);

  final totalEmails = await senderDao.getTotalEmailCount();
  final allSenders = await senderDao.getAllSenders();
  final categoryBreakdown = await senderDao.getCategoryBreakdown();
  final topDomains = await senderDao.getTopDomains(10);

  final syncState = await syncStateDao.getSyncState();
  final deletedEmails = syncState?.deletedEmailsCount ?? 0;

  return InboxStats(
    totalEmails: totalEmails,
    totalSenders: allSenders.length,
    deletedEmails: deletedEmails,
    categoryBreakdown: categoryBreakdown,
    topDomains: topDomains,
  );
});
