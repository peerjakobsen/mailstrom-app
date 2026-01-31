import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sender_table.dart';

part 'sender_dao.g.dart';

@DriftAccessor(tables: [SenderTable])
class SenderDao extends DatabaseAccessor<AppDatabase>
    with _$SenderDaoMixin {
  SenderDao(super.db);

  Stream<List<SenderTableData>> watchAllSenders() {
    return (select(senderTable)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.emailCount,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<void> upsertSender(SenderTableCompanion sender) {
    return into(senderTable).insertOnConflictUpdate(sender);
  }

  Future<void> upsertSenders(
    List<SenderTableCompanion> senders,
  ) {
    return batch((b) {
      for (final sender in senders) {
        b.insert(senderTable, sender, onConflict: DoUpdate((_) => sender));
      }
    });
  }

  Future<int> deleteSender(String email) {
    return (delete(senderTable)
          ..where((t) => t.email.equals(email)))
        .go();
  }

  Future<SenderTableData?> getSenderByEmail(String email) {
    return (select(senderTable)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();
  }

  Future<void> markUnsubscribed(String email) {
    return (update(senderTable)..where((t) => t.email.equals(email))).write(
      const SenderTableCompanion(isUnsubscribed: Value(true)),
    );
  }

  Future<void> deleteAllSenders() {
    return delete(senderTable).go();
  }

  Future<void> updateCategory(String email, String category) {
    return (update(senderTable)..where((t) => t.email.equals(email))).write(
      SenderTableCompanion(category: Value(category)),
    );
  }

  Future<List<SenderTableData>> getTopSenders(int limit) {
    return (select(senderTable)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.emailCount,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }

  Future<Map<String, int>> getCategoryBreakdown() async {
    final result = await customSelect(
      'SELECT category, COUNT(*) AS count FROM sender_table GROUP BY category',
    ).get();
    return {
      for (final row in result)
        row.read<String>('category'): row.read<int>('count'),
    };
  }

  Future<int> getTotalEmailCount() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(email_count), 0) AS total FROM sender_table',
    ).getSingle();
    return result.read<int>('total');
  }

  Future<List<SenderTableData>> getAllSenders() {
    return select(senderTable).get();
  }
}
