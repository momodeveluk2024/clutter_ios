import 'package:health/health.dart';

/// Phase 4: HealthKit (iOS) + Health Connect (Android) two-way sync.
///
/// **Native config required:**
///   - iOS: Info.plist NSHealthShareUsageDescription + NSHealthUpdateUsageDescription;
///     Xcode → Capabilities → HealthKit.
///   - Android: AndroidManifest health permissions and a HealthConnectClient
///     activity registration. See `health` package README.
///
/// We pull active calories + workouts (so the kcal target adjusts to actual
/// burn) and push macros + total kcal so other health apps can see the
/// nutrition picture.
class HealthSyncService {
  HealthSyncService._();
  static final HealthSyncService instance = HealthSyncService._();

  static const _readTypes = <HealthDataType>[
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  static const _writeTypes = <HealthDataType>[
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
  ];

  final Health _health = Health();

  Future<bool> requestAuthorization() async {
    await _health.configure();
    final permissions = [
      ..._readTypes.map((_) => HealthDataAccess.READ),
      ..._writeTypes.map((_) => HealthDataAccess.WRITE),
    ];
    return _health.requestAuthorization(
      [..._readTypes, ..._writeTypes],
      permissions: permissions,
    );
  }

  Future<int?> readActiveCaloriesToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: start,
      endTime: now,
    );
    if (data.isEmpty) return null;
    var total = 0.0;
    for (final p in data) {
      final value = p.value;
      if (value is NumericHealthValue) {
        total += value.numericValue.toDouble();
      }
    }
    return total.round();
  }

  Future<bool> writeMealMacros({
    required DateTime when,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final ok1 = await _health.writeHealthData(
      value: kcal,
      type: HealthDataType.DIETARY_ENERGY_CONSUMED,
      startTime: when,
      endTime: when,
    );
    final ok2 = await _health.writeHealthData(
      value: proteinG,
      type: HealthDataType.DIETARY_PROTEIN_CONSUMED,
      startTime: when,
      endTime: when,
    );
    final ok3 = await _health.writeHealthData(
      value: carbsG,
      type: HealthDataType.DIETARY_CARBS_CONSUMED,
      startTime: when,
      endTime: when,
    );
    final ok4 = await _health.writeHealthData(
      value: fatG,
      type: HealthDataType.DIETARY_FATS_CONSUMED,
      startTime: when,
      endTime: when,
    );
    return ok1 && ok2 && ok3 && ok4;
  }
}
