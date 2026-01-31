import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/email_dao.dart';
import 'daos/sender_dao.dart';
import 'daos/sync_state_dao.dart';
import 'tables/email_summary_table.dart';
import 'tables/sender_table.dart';
import 'tables/sync_state_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [SenderTable, EmailSummaryTable, SyncStateTable],
  daos: [SenderDao, EmailDao, SyncStateDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create indexes manually
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_email_sender '
          'ON email_summary_table (sender_email)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_email_date '
          'ON email_summary_table (date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sender_domain '
          'ON sender_table (domain)',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await customStatement(
            'ALTER TABLE sender_table '
            'ADD COLUMN is_unsubscribed INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mailstrom.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final senderDaoProvider = Provider<SenderDao>((ref) {
  return ref.watch(databaseProvider).senderDao;
});

final emailDaoProvider = Provider<EmailDao>((ref) {
  return ref.watch(databaseProvider).emailDao;
});

final syncStateDaoProvider = Provider<SyncStateDao>((ref) {
  return ref.watch(databaseProvider).syncStateDao;
});
