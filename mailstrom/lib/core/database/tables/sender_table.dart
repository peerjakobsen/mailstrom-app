import 'package:drift/drift.dart';

class SenderTable extends Table {
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get domain => text()();
  IntColumn get emailCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get mostRecent => dateTime()();
  TextColumn get category => text().withDefault(const Constant('unknown'))();
  TextColumn get unsubscribeLink => text().nullable()();
  BoolColumn get isUnsubscribed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {email};

  @override
  List<Set<Column>> get uniqueKeys => [];
}
