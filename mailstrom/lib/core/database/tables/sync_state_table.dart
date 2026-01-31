import 'package:drift/drift.dart';

class SyncStateTable extends Table {
  IntColumn get id =>
      integer().withDefault(const Constant(1))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  TextColumn get historyId => text().nullable()();
  IntColumn get totalEmails =>
      integer().withDefault(const Constant(0))();
  IntColumn get processedEmails =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
