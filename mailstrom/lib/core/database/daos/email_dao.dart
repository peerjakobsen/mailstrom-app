import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/email_summary_table.dart';

part 'email_dao.g.dart';

@DriftAccessor(tables: [EmailSummaryTable])
class EmailDao extends DatabaseAccessor<AppDatabase>
    with _$EmailDaoMixin {
  EmailDao(super.db);

  Stream<List<EmailSummaryTableData>> watchEmailsBySender(
    String senderEmail,
  ) {
    return (select(emailSummaryTable)
          ..where((t) => t.senderEmail.equals(senderEmail))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<void> insertEmails(
    List<EmailSummaryTableCompanion> emails,
  ) {
    return batch((b) {
      b.insertAll(
        emailSummaryTable,
        emails,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<int> deleteEmailsBySender(String senderEmail) {
    return (delete(emailSummaryTable)
          ..where((t) => t.senderEmail.equals(senderEmail)))
        .go();
  }

  Future<EmailSummaryTableData?> getEmailById(String id) {
    return (select(emailSummaryTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<EmailSummaryTableData>> getEmailsBySender(
    String senderEmail,
  ) {
    return (select(emailSummaryTable)
          ..where((t) => t.senderEmail.equals(senderEmail)))
        .get();
  }

  Future<List<String>> getEmailIdsBySender(
    String senderEmail,
  ) async {
    final emails = await (select(emailSummaryTable)
          ..where((t) => t.senderEmail.equals(senderEmail)))
        .get();
    return emails.map((e) => e.id).toList();
  }

  Future<void> deleteEmailsByIds(List<String> ids) {
    return (delete(emailSummaryTable)
          ..where((t) => t.id.isIn(ids)))
        .go();
  }

  Future<List<String>> getAllEmailIds() async {
    final rows = await (selectOnly(emailSummaryTable)
          ..addColumns([emailSummaryTable.id]))
        .get();
    return rows.map((r) => r.read(emailSummaryTable.id)!).toList();
  }

  Future<void> deleteAllEmails() {
    return delete(emailSummaryTable).go();
  }
}
