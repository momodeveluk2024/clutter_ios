import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_db.g.dart';

// Phase 0 of the personalization roadmap. Four tables drive offline + the
// learning loop:
//   - CachedFoods:    last-seen food summaries, so search/log works offline
//                     and the "your usuals" row renders without a round trip.
//   - LocalMealLogs:  write-through cache of user logs. The server is still
//                     source of truth, but the UI reads from here first.
//   - FrequentFoods:  rolling 30d frequency + last-seen, used to rank
//                     personal shortcuts and short-circuit duplicate fetches.
//   - PendingSync:    write-ahead queue for actions made offline. Drained by
//                     a sync worker once connectivity returns.

class CachedFoods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get servingSizeG => real().nullable()();
  TextColumn get imageUrl => text().nullable()();
  // Full server payload as JSON, so we can reconstruct a FoodSummary or
  // FoodDetail without losing fields the local schema doesn't model.
  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMealLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get foodId => text()();
  TextColumn get mealType => text()(); // breakfast|lunch|dinner|snack
  RealColumn get servingsLogged => real()();
  DateTimeColumn get loggedAt => dateTime()();
  // 'synced' | 'pending' | 'failed' — pending rows are also in PendingSync.
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FrequentFoods extends Table {
  TextColumn get userId => text()();
  TextColumn get foodId => text()();
  IntColumn get count30d => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastLoggedAt => dateTime()();
  TextColumn get lastMealType => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId, foodId};
}

class PendingSync extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 'log_meal' | 'delete_log' | 'add_favorite' | 'remove_favorite' | 'rec_feedback'
  TextColumn get action => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [CachedFoods, LocalMealLogs, FrequentFoods, PendingSync])
class LocalDb extends _$LocalDb {
  LocalDb() : super(_open());

  static LocalDb? _instance;
  static LocalDb get instance => _instance ??= LocalDb();

  @override
  int get schemaVersion => 1;

  Future<void> upsertCachedFood({
    required String id,
    required String name,
    String? brand,
    String? category,
    double? servingSizeG,
    String? imageUrl,
    required String rawJson,
  }) {
    return into(cachedFoods).insertOnConflictUpdate(
      CachedFoodsCompanion.insert(
        id: id,
        name: name,
        brand: Value(brand),
        category: Value(category),
        servingSizeG: Value(servingSizeG),
        imageUrl: Value(imageUrl),
        rawJson: rawJson,
        cachedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<FrequentFood>> topFrequentFoods(String userId, {int limit = 8}) {
    return (select(frequentFoods)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.count30d),
            (t) => OrderingTerm.desc(t.lastLoggedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> recordLocalLog({
    required String id,
    required String userId,
    required String foodId,
    required String mealType,
    required double servingsLogged,
    DateTime? loggedAt,
    String syncStatus = 'pending',
  }) async {
    final now = DateTime.now().toUtc();
    await into(localMealLogs).insertOnConflictUpdate(
      LocalMealLogsCompanion.insert(
        id: id,
        userId: userId,
        foodId: foodId,
        mealType: mealType,
        servingsLogged: servingsLogged,
        loggedAt: loggedAt ?? now,
        syncStatus: Value(syncStatus),
        createdAt: now,
      ),
    );
    await _bumpFrequency(userId: userId, foodId: foodId, mealType: mealType);
  }

  Future<void> _bumpFrequency({
    required String userId,
    required String foodId,
    required String mealType,
  }) async {
    final existing = await (select(frequentFoods)
          ..where((t) => t.userId.equals(userId) & t.foodId.equals(foodId)))
        .getSingleOrNull();
    final now = DateTime.now().toUtc();
    if (existing == null) {
      await into(frequentFoods).insert(
        FrequentFoodsCompanion.insert(
          userId: userId,
          foodId: foodId,
          count30d: const Value(1),
          lastLoggedAt: now,
          lastMealType: Value(mealType),
        ),
      );
    } else {
      await (update(frequentFoods)
            ..where((t) => t.userId.equals(userId) & t.foodId.equals(foodId)))
          .write(
        FrequentFoodsCompanion(
          count30d: Value(existing.count30d + 1),
          lastLoggedAt: Value(now),
          lastMealType: Value(mealType),
        ),
      );
    }
  }

  Future<int> queueSync({required String action, required String payloadJson}) {
    return into(pendingSync).insert(
      PendingSyncCompanion.insert(
        action: action,
        payloadJson: payloadJson,
        queuedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<PendingSyncData>> nextSyncBatch({int limit = 25}) {
    return (select(pendingSync)
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteSync(int id) {
    return (delete(pendingSync)..where((t) => t.id.equals(id))).go();
  }
}

QueryExecutor _open() {
  // drift_flutter handles platform-appropriate paths and isolates.
  return driftDatabase(name: 'nutrimate_local');
}
