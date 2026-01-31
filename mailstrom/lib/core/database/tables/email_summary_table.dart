import 'package:drift/drift.dart';

class EmailSummaryTable extends Table {
  TextColumn get id => text()();
  TextColumn get senderEmail => text()();
  TextColumn get subject => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get snippet => text().withDefault(const Constant(''))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get unsubscribeLink => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_email_sender', columns: {#senderEmail})
@TableIndex(name: 'idx_email_date', columns: {#date})
class EmailSummaryIndexes {}
