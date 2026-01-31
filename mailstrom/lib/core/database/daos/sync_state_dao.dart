import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_state_table.dart';

part 'sync_state_dao.g.dart';

@DriftAccessor(tables: [SyncStateTable])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<SyncStateTableData?> getSyncState() {
    return (select(syncStateTable)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> updateSyncState(SyncStateTableCompanion state) {
    return into(syncStateTable).insertOnConflictUpdate(
      state.copyWith(id: const Value(1)),
    );
  }

  Future<void> clearSyncState() {
    return delete(syncStateTable).go();
  }
}
