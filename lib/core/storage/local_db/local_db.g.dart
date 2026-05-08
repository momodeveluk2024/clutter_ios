// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $CachedFoodsTable extends CachedFoods
    with TableInfo<$CachedFoodsTable, CachedFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingSizeGMeta = const VerificationMeta(
    'servingSizeG',
  );
  @override
  late final GeneratedColumn<double> servingSizeG = GeneratedColumn<double>(
    'serving_size_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    category,
    servingSizeG,
    imageUrl,
    rawJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('serving_size_g')) {
      context.handle(
        _servingSizeGMeta,
        servingSizeG.isAcceptableOrUnknown(
          data['serving_size_g']!,
          _servingSizeGMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      servingSizeG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_size_g'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedFoodsTable createAlias(String alias) {
    return $CachedFoodsTable(attachedDatabase, alias);
  }
}

class CachedFood extends DataClass implements Insertable<CachedFood> {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final double? servingSizeG;
  final String? imageUrl;
  final String rawJson;
  final DateTime cachedAt;
  const CachedFood({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.servingSizeG,
    this.imageUrl,
    required this.rawJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || servingSizeG != null) {
      map['serving_size_g'] = Variable<double>(servingSizeG);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFoodsCompanion toCompanion(bool nullToAbsent) {
    return CachedFoodsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      servingSizeG: servingSizeG == null && nullToAbsent
          ? const Value.absent()
          : Value(servingSizeG),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFood(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      category: serializer.fromJson<String?>(json['category']),
      servingSizeG: serializer.fromJson<double?>(json['servingSizeG']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'category': serializer.toJson<String?>(category),
      'servingSizeG': serializer.toJson<double?>(servingSizeG),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFood copyWith({
    String? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<double?> servingSizeG = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    String? rawJson,
    DateTime? cachedAt,
  }) => CachedFood(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    category: category.present ? category.value : this.category,
    servingSizeG: servingSizeG.present ? servingSizeG.value : this.servingSizeG,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    rawJson: rawJson ?? this.rawJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedFood copyWithCompanion(CachedFoodsCompanion data) {
    return CachedFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      category: data.category.present ? data.category.value : this.category,
      servingSizeG: data.servingSizeG.present
          ? data.servingSizeG.value
          : this.servingSizeG,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('category: $category, ')
          ..write('servingSizeG: $servingSizeG, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    category,
    servingSizeG,
    imageUrl,
    rawJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.category == this.category &&
          other.servingSizeG == this.servingSizeG &&
          other.imageUrl == this.imageUrl &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedFoodsCompanion extends UpdateCompanion<CachedFood> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> category;
  final Value<double?> servingSizeG;
  final Value<String?> imageUrl;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.category = const Value.absent(),
    this.servingSizeG = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFoodsCompanion.insert({
    required String id,
    required String name,
    this.brand = const Value.absent(),
    this.category = const Value.absent(),
    this.servingSizeG = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       rawJson = Value(rawJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedFood> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? category,
    Expression<double>? servingSizeG,
    Expression<String>? imageUrl,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (category != null) 'category': category,
      if (servingSizeG != null) 'serving_size_g': servingSizeG,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFoodsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? category,
    Value<double?>? servingSizeG,
    Value<String?>? imageUrl,
    Value<String>? rawJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      servingSizeG: servingSizeG ?? this.servingSizeG,
      imageUrl: imageUrl ?? this.imageUrl,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (servingSizeG.present) {
      map['serving_size_g'] = Variable<double>(servingSizeG.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('category: $category, ')
          ..write('servingSizeG: $servingSizeG, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMealLogsTable extends LocalMealLogs
    with TableInfo<$LocalMealLogsTable, LocalMealLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsLoggedMeta = const VerificationMeta(
    'servingsLogged',
  );
  @override
  late final GeneratedColumn<double> servingsLogged = GeneratedColumn<double>(
    'servings_logged',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    foodId,
    mealType,
    servingsLogged,
    loggedAt,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meal_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMealLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('servings_logged')) {
      context.handle(
        _servingsLoggedMeta,
        servingsLogged.isAcceptableOrUnknown(
          data['servings_logged']!,
          _servingsLoggedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_servingsLoggedMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMealLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMealLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      )!,
      servingsLogged: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}servings_logged'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalMealLogsTable createAlias(String alias) {
    return $LocalMealLogsTable(attachedDatabase, alias);
  }
}

class LocalMealLog extends DataClass implements Insertable<LocalMealLog> {
  final String id;
  final String userId;
  final String foodId;
  final String mealType;
  final double servingsLogged;
  final DateTime loggedAt;
  final String syncStatus;
  final DateTime createdAt;
  const LocalMealLog({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.mealType,
    required this.servingsLogged,
    required this.loggedAt,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['food_id'] = Variable<String>(foodId);
    map['meal_type'] = Variable<String>(mealType);
    map['servings_logged'] = Variable<double>(servingsLogged);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalMealLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      foodId: Value(foodId),
      mealType: Value(mealType),
      servingsLogged: Value(servingsLogged),
      loggedAt: Value(loggedAt),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalMealLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMealLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      mealType: serializer.fromJson<String>(json['mealType']),
      servingsLogged: serializer.fromJson<double>(json['servingsLogged']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'foodId': serializer.toJson<String>(foodId),
      'mealType': serializer.toJson<String>(mealType),
      'servingsLogged': serializer.toJson<double>(servingsLogged),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalMealLog copyWith({
    String? id,
    String? userId,
    String? foodId,
    String? mealType,
    double? servingsLogged,
    DateTime? loggedAt,
    String? syncStatus,
    DateTime? createdAt,
  }) => LocalMealLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    foodId: foodId ?? this.foodId,
    mealType: mealType ?? this.mealType,
    servingsLogged: servingsLogged ?? this.servingsLogged,
    loggedAt: loggedAt ?? this.loggedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalMealLog copyWithCompanion(LocalMealLogsCompanion data) {
    return LocalMealLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      servingsLogged: data.servingsLogged.present
          ? data.servingsLogged.value
          : this.servingsLogged,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('mealType: $mealType, ')
          ..write('servingsLogged: $servingsLogged, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    foodId,
    mealType,
    servingsLogged,
    loggedAt,
    syncStatus,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMealLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.foodId == this.foodId &&
          other.mealType == this.mealType &&
          other.servingsLogged == this.servingsLogged &&
          other.loggedAt == this.loggedAt &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalMealLogsCompanion extends UpdateCompanion<LocalMealLog> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> foodId;
  final Value<String> mealType;
  final Value<double> servingsLogged;
  final Value<DateTime> loggedAt;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalMealLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.mealType = const Value.absent(),
    this.servingsLogged = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMealLogsCompanion.insert({
    required String id,
    required String userId,
    required String foodId,
    required String mealType,
    required double servingsLogged,
    required DateTime loggedAt,
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       foodId = Value(foodId),
       mealType = Value(mealType),
       servingsLogged = Value(servingsLogged),
       loggedAt = Value(loggedAt),
       createdAt = Value(createdAt);
  static Insertable<LocalMealLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? foodId,
    Expression<String>? mealType,
    Expression<double>? servingsLogged,
    Expression<DateTime>? loggedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      if (mealType != null) 'meal_type': mealType,
      if (servingsLogged != null) 'servings_logged': servingsLogged,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMealLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? foodId,
    Value<String>? mealType,
    Value<double>? servingsLogged,
    Value<DateTime>? loggedAt,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalMealLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      mealType: mealType ?? this.mealType,
      servingsLogged: servingsLogged ?? this.servingsLogged,
      loggedAt: loggedAt ?? this.loggedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (servingsLogged.present) {
      map['servings_logged'] = Variable<double>(servingsLogged.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('mealType: $mealType, ')
          ..write('servingsLogged: $servingsLogged, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrequentFoodsTable extends FrequentFoods
    with TableInfo<$FrequentFoodsTable, FrequentFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequentFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _count30dMeta = const VerificationMeta(
    'count30d',
  );
  @override
  late final GeneratedColumn<int> count30d = GeneratedColumn<int>(
    'count30d',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastLoggedAtMeta = const VerificationMeta(
    'lastLoggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoggedAt = GeneratedColumn<DateTime>(
    'last_logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMealTypeMeta = const VerificationMeta(
    'lastMealType',
  );
  @override
  late final GeneratedColumn<String> lastMealType = GeneratedColumn<String>(
    'last_meal_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    foodId,
    count30d,
    lastLoggedAt,
    lastMealType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frequent_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrequentFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('count30d')) {
      context.handle(
        _count30dMeta,
        count30d.isAcceptableOrUnknown(data['count30d']!, _count30dMeta),
      );
    }
    if (data.containsKey('last_logged_at')) {
      context.handle(
        _lastLoggedAtMeta,
        lastLoggedAt.isAcceptableOrUnknown(
          data['last_logged_at']!,
          _lastLoggedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastLoggedAtMeta);
    }
    if (data.containsKey('last_meal_type')) {
      context.handle(
        _lastMealTypeMeta,
        lastMealType.isAcceptableOrUnknown(
          data['last_meal_type']!,
          _lastMealTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, foodId};
  @override
  FrequentFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrequentFood(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      count30d: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count30d'],
      )!,
      lastLoggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_logged_at'],
      )!,
      lastMealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_meal_type'],
      ),
    );
  }

  @override
  $FrequentFoodsTable createAlias(String alias) {
    return $FrequentFoodsTable(attachedDatabase, alias);
  }
}

class FrequentFood extends DataClass implements Insertable<FrequentFood> {
  final String userId;
  final String foodId;
  final int count30d;
  final DateTime lastLoggedAt;
  final String? lastMealType;
  const FrequentFood({
    required this.userId,
    required this.foodId,
    required this.count30d,
    required this.lastLoggedAt,
    this.lastMealType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['food_id'] = Variable<String>(foodId);
    map['count30d'] = Variable<int>(count30d);
    map['last_logged_at'] = Variable<DateTime>(lastLoggedAt);
    if (!nullToAbsent || lastMealType != null) {
      map['last_meal_type'] = Variable<String>(lastMealType);
    }
    return map;
  }

  FrequentFoodsCompanion toCompanion(bool nullToAbsent) {
    return FrequentFoodsCompanion(
      userId: Value(userId),
      foodId: Value(foodId),
      count30d: Value(count30d),
      lastLoggedAt: Value(lastLoggedAt),
      lastMealType: lastMealType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMealType),
    );
  }

  factory FrequentFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrequentFood(
      userId: serializer.fromJson<String>(json['userId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      count30d: serializer.fromJson<int>(json['count30d']),
      lastLoggedAt: serializer.fromJson<DateTime>(json['lastLoggedAt']),
      lastMealType: serializer.fromJson<String?>(json['lastMealType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'foodId': serializer.toJson<String>(foodId),
      'count30d': serializer.toJson<int>(count30d),
      'lastLoggedAt': serializer.toJson<DateTime>(lastLoggedAt),
      'lastMealType': serializer.toJson<String?>(lastMealType),
    };
  }

  FrequentFood copyWith({
    String? userId,
    String? foodId,
    int? count30d,
    DateTime? lastLoggedAt,
    Value<String?> lastMealType = const Value.absent(),
  }) => FrequentFood(
    userId: userId ?? this.userId,
    foodId: foodId ?? this.foodId,
    count30d: count30d ?? this.count30d,
    lastLoggedAt: lastLoggedAt ?? this.lastLoggedAt,
    lastMealType: lastMealType.present ? lastMealType.value : this.lastMealType,
  );
  FrequentFood copyWithCompanion(FrequentFoodsCompanion data) {
    return FrequentFood(
      userId: data.userId.present ? data.userId.value : this.userId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      count30d: data.count30d.present ? data.count30d.value : this.count30d,
      lastLoggedAt: data.lastLoggedAt.present
          ? data.lastLoggedAt.value
          : this.lastLoggedAt,
      lastMealType: data.lastMealType.present
          ? data.lastMealType.value
          : this.lastMealType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrequentFood(')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('count30d: $count30d, ')
          ..write('lastLoggedAt: $lastLoggedAt, ')
          ..write('lastMealType: $lastMealType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, foodId, count30d, lastLoggedAt, lastMealType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrequentFood &&
          other.userId == this.userId &&
          other.foodId == this.foodId &&
          other.count30d == this.count30d &&
          other.lastLoggedAt == this.lastLoggedAt &&
          other.lastMealType == this.lastMealType);
}

class FrequentFoodsCompanion extends UpdateCompanion<FrequentFood> {
  final Value<String> userId;
  final Value<String> foodId;
  final Value<int> count30d;
  final Value<DateTime> lastLoggedAt;
  final Value<String?> lastMealType;
  final Value<int> rowid;
  const FrequentFoodsCompanion({
    this.userId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.count30d = const Value.absent(),
    this.lastLoggedAt = const Value.absent(),
    this.lastMealType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrequentFoodsCompanion.insert({
    required String userId,
    required String foodId,
    this.count30d = const Value.absent(),
    required DateTime lastLoggedAt,
    this.lastMealType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       foodId = Value(foodId),
       lastLoggedAt = Value(lastLoggedAt);
  static Insertable<FrequentFood> custom({
    Expression<String>? userId,
    Expression<String>? foodId,
    Expression<int>? count30d,
    Expression<DateTime>? lastLoggedAt,
    Expression<String>? lastMealType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      if (count30d != null) 'count30d': count30d,
      if (lastLoggedAt != null) 'last_logged_at': lastLoggedAt,
      if (lastMealType != null) 'last_meal_type': lastMealType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrequentFoodsCompanion copyWith({
    Value<String>? userId,
    Value<String>? foodId,
    Value<int>? count30d,
    Value<DateTime>? lastLoggedAt,
    Value<String?>? lastMealType,
    Value<int>? rowid,
  }) {
    return FrequentFoodsCompanion(
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      count30d: count30d ?? this.count30d,
      lastLoggedAt: lastLoggedAt ?? this.lastLoggedAt,
      lastMealType: lastMealType ?? this.lastMealType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (count30d.present) {
      map['count30d'] = Variable<int>(count30d.value);
    }
    if (lastLoggedAt.present) {
      map['last_logged_at'] = Variable<DateTime>(lastLoggedAt.value);
    }
    if (lastMealType.present) {
      map['last_meal_type'] = Variable<String>(lastMealType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrequentFoodsCompanion(')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('count30d: $count30d, ')
          ..write('lastLoggedAt: $lastLoggedAt, ')
          ..write('lastMealType: $lastMealType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncTable extends PendingSync
    with TableInfo<$PendingSyncTable, PendingSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    action,
    payloadJson,
    queuedAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingSyncTable createAlias(String alias) {
    return $PendingSyncTable(attachedDatabase, alias);
  }
}

class PendingSyncData extends DataClass implements Insertable<PendingSyncData> {
  final int id;
  final String action;
  final String payloadJson;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;
  const PendingSyncData({
    required this.id,
    required this.action,
    required this.payloadJson,
    required this.queuedAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['payload_json'] = Variable<String>(payloadJson);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingSyncCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncCompanion(
      id: Value(id),
      action: Value(action),
      payloadJson: Value(payloadJson),
      queuedAt: Value(queuedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncData(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingSyncData copyWith({
    int? id,
    String? action,
    String? payloadJson,
    DateTime? queuedAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => PendingSyncData(
    id: id ?? this.id,
    action: action ?? this.action,
    payloadJson: payloadJson ?? this.payloadJson,
    queuedAt: queuedAt ?? this.queuedAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingSyncData copyWithCompanion(PendingSyncCompanion data) {
    return PendingSyncData(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncData(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, action, payloadJson, queuedAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncData &&
          other.id == this.id &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.queuedAt == this.queuedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class PendingSyncCompanion extends UpdateCompanion<PendingSyncData> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> payloadJson;
  final Value<DateTime> queuedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const PendingSyncCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingSyncCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String payloadJson,
    required DateTime queuedAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : action = Value(action),
       payloadJson = Value(payloadJson),
       queuedAt = Value(queuedAt);
  static Insertable<PendingSyncData> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<DateTime>? queuedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingSyncCompanion copyWith({
    Value<int>? id,
    Value<String>? action,
    Value<String>? payloadJson,
    Value<DateTime>? queuedAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return PendingSyncCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(e);
  $LocalDbManager get managers => $LocalDbManager(this);
  late final $CachedFoodsTable cachedFoods = $CachedFoodsTable(this);
  late final $LocalMealLogsTable localMealLogs = $LocalMealLogsTable(this);
  late final $FrequentFoodsTable frequentFoods = $FrequentFoodsTable(this);
  late final $PendingSyncTable pendingSync = $PendingSyncTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedFoods,
    localMealLogs,
    frequentFoods,
    pendingSync,
  ];
}

typedef $$CachedFoodsTableCreateCompanionBuilder =
    CachedFoodsCompanion Function({
      required String id,
      required String name,
      Value<String?> brand,
      Value<String?> category,
      Value<double?> servingSizeG,
      Value<String?> imageUrl,
      required String rawJson,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedFoodsTableUpdateCompanionBuilder =
    CachedFoodsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> category,
      Value<double?> servingSizeG,
      Value<String?> imageUrl,
      Value<String> rawJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedFoodsTableFilterComposer
    extends Composer<_$LocalDb, $CachedFoodsTable> {
  $$CachedFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFoodsTableOrderingComposer
    extends Composer<_$LocalDb, $CachedFoodsTable> {
  $$CachedFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFoodsTableAnnotationComposer
    extends Composer<_$LocalDb, $CachedFoodsTable> {
  $$CachedFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFoodsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $CachedFoodsTable,
          CachedFood,
          $$CachedFoodsTableFilterComposer,
          $$CachedFoodsTableOrderingComposer,
          $$CachedFoodsTableAnnotationComposer,
          $$CachedFoodsTableCreateCompanionBuilder,
          $$CachedFoodsTableUpdateCompanionBuilder,
          (
            CachedFood,
            BaseReferences<_$LocalDb, $CachedFoodsTable, CachedFood>,
          ),
          CachedFood,
          PrefetchHooks Function()
        > {
  $$CachedFoodsTableTableManager(_$LocalDb db, $CachedFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> servingSizeG = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodsCompanion(
                id: id,
                name: name,
                brand: brand,
                category: category,
                servingSizeG: servingSizeG,
                imageUrl: imageUrl,
                rawJson: rawJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> servingSizeG = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required String rawJson,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFoodsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                category: category,
                servingSizeG: servingSizeG,
                imageUrl: imageUrl,
                rawJson: rawJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $CachedFoodsTable,
      CachedFood,
      $$CachedFoodsTableFilterComposer,
      $$CachedFoodsTableOrderingComposer,
      $$CachedFoodsTableAnnotationComposer,
      $$CachedFoodsTableCreateCompanionBuilder,
      $$CachedFoodsTableUpdateCompanionBuilder,
      (CachedFood, BaseReferences<_$LocalDb, $CachedFoodsTable, CachedFood>),
      CachedFood,
      PrefetchHooks Function()
    >;
typedef $$LocalMealLogsTableCreateCompanionBuilder =
    LocalMealLogsCompanion Function({
      required String id,
      required String userId,
      required String foodId,
      required String mealType,
      required double servingsLogged,
      required DateTime loggedAt,
      Value<String> syncStatus,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalMealLogsTableUpdateCompanionBuilder =
    LocalMealLogsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> foodId,
      Value<String> mealType,
      Value<double> servingsLogged,
      Value<DateTime> loggedAt,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalMealLogsTableFilterComposer
    extends Composer<_$LocalDb, $LocalMealLogsTable> {
  $$LocalMealLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingsLogged => $composableBuilder(
    column: $table.servingsLogged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMealLogsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalMealLogsTable> {
  $$LocalMealLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingsLogged => $composableBuilder(
    column: $table.servingsLogged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMealLogsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalMealLogsTable> {
  $$LocalMealLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<double> get servingsLogged => $composableBuilder(
    column: $table.servingsLogged,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalMealLogsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $LocalMealLogsTable,
          LocalMealLog,
          $$LocalMealLogsTableFilterComposer,
          $$LocalMealLogsTableOrderingComposer,
          $$LocalMealLogsTableAnnotationComposer,
          $$LocalMealLogsTableCreateCompanionBuilder,
          $$LocalMealLogsTableUpdateCompanionBuilder,
          (
            LocalMealLog,
            BaseReferences<_$LocalDb, $LocalMealLogsTable, LocalMealLog>,
          ),
          LocalMealLog,
          PrefetchHooks Function()
        > {
  $$LocalMealLogsTableTableManager(_$LocalDb db, $LocalMealLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<String> mealType = const Value.absent(),
                Value<double> servingsLogged = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealLogsCompanion(
                id: id,
                userId: userId,
                foodId: foodId,
                mealType: mealType,
                servingsLogged: servingsLogged,
                loggedAt: loggedAt,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String foodId,
                required String mealType,
                required double servingsLogged,
                required DateTime loggedAt,
                Value<String> syncStatus = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMealLogsCompanion.insert(
                id: id,
                userId: userId,
                foodId: foodId,
                mealType: mealType,
                servingsLogged: servingsLogged,
                loggedAt: loggedAt,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMealLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $LocalMealLogsTable,
      LocalMealLog,
      $$LocalMealLogsTableFilterComposer,
      $$LocalMealLogsTableOrderingComposer,
      $$LocalMealLogsTableAnnotationComposer,
      $$LocalMealLogsTableCreateCompanionBuilder,
      $$LocalMealLogsTableUpdateCompanionBuilder,
      (
        LocalMealLog,
        BaseReferences<_$LocalDb, $LocalMealLogsTable, LocalMealLog>,
      ),
      LocalMealLog,
      PrefetchHooks Function()
    >;
typedef $$FrequentFoodsTableCreateCompanionBuilder =
    FrequentFoodsCompanion Function({
      required String userId,
      required String foodId,
      Value<int> count30d,
      required DateTime lastLoggedAt,
      Value<String?> lastMealType,
      Value<int> rowid,
    });
typedef $$FrequentFoodsTableUpdateCompanionBuilder =
    FrequentFoodsCompanion Function({
      Value<String> userId,
      Value<String> foodId,
      Value<int> count30d,
      Value<DateTime> lastLoggedAt,
      Value<String?> lastMealType,
      Value<int> rowid,
    });

class $$FrequentFoodsTableFilterComposer
    extends Composer<_$LocalDb, $FrequentFoodsTable> {
  $$FrequentFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count30d => $composableBuilder(
    column: $table.count30d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoggedAt => $composableBuilder(
    column: $table.lastLoggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMealType => $composableBuilder(
    column: $table.lastMealType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FrequentFoodsTableOrderingComposer
    extends Composer<_$LocalDb, $FrequentFoodsTable> {
  $$FrequentFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count30d => $composableBuilder(
    column: $table.count30d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoggedAt => $composableBuilder(
    column: $table.lastLoggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMealType => $composableBuilder(
    column: $table.lastMealType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FrequentFoodsTableAnnotationComposer
    extends Composer<_$LocalDb, $FrequentFoodsTable> {
  $$FrequentFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<int> get count30d =>
      $composableBuilder(column: $table.count30d, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoggedAt => $composableBuilder(
    column: $table.lastLoggedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMealType => $composableBuilder(
    column: $table.lastMealType,
    builder: (column) => column,
  );
}

class $$FrequentFoodsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $FrequentFoodsTable,
          FrequentFood,
          $$FrequentFoodsTableFilterComposer,
          $$FrequentFoodsTableOrderingComposer,
          $$FrequentFoodsTableAnnotationComposer,
          $$FrequentFoodsTableCreateCompanionBuilder,
          $$FrequentFoodsTableUpdateCompanionBuilder,
          (
            FrequentFood,
            BaseReferences<_$LocalDb, $FrequentFoodsTable, FrequentFood>,
          ),
          FrequentFood,
          PrefetchHooks Function()
        > {
  $$FrequentFoodsTableTableManager(_$LocalDb db, $FrequentFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequentFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequentFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequentFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<int> count30d = const Value.absent(),
                Value<DateTime> lastLoggedAt = const Value.absent(),
                Value<String?> lastMealType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrequentFoodsCompanion(
                userId: userId,
                foodId: foodId,
                count30d: count30d,
                lastLoggedAt: lastLoggedAt,
                lastMealType: lastMealType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String foodId,
                Value<int> count30d = const Value.absent(),
                required DateTime lastLoggedAt,
                Value<String?> lastMealType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrequentFoodsCompanion.insert(
                userId: userId,
                foodId: foodId,
                count30d: count30d,
                lastLoggedAt: lastLoggedAt,
                lastMealType: lastMealType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FrequentFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $FrequentFoodsTable,
      FrequentFood,
      $$FrequentFoodsTableFilterComposer,
      $$FrequentFoodsTableOrderingComposer,
      $$FrequentFoodsTableAnnotationComposer,
      $$FrequentFoodsTableCreateCompanionBuilder,
      $$FrequentFoodsTableUpdateCompanionBuilder,
      (
        FrequentFood,
        BaseReferences<_$LocalDb, $FrequentFoodsTable, FrequentFood>,
      ),
      FrequentFood,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncTableCreateCompanionBuilder =
    PendingSyncCompanion Function({
      Value<int> id,
      required String action,
      required String payloadJson,
      required DateTime queuedAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$PendingSyncTableUpdateCompanionBuilder =
    PendingSyncCompanion Function({
      Value<int> id,
      Value<String> action,
      Value<String> payloadJson,
      Value<DateTime> queuedAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$PendingSyncTableFilterComposer
    extends Composer<_$LocalDb, $PendingSyncTable> {
  $$PendingSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncTableOrderingComposer
    extends Composer<_$LocalDb, $PendingSyncTable> {
  $$PendingSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncTableAnnotationComposer
    extends Composer<_$LocalDb, $PendingSyncTable> {
  $$PendingSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingSyncTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $PendingSyncTable,
          PendingSyncData,
          $$PendingSyncTableFilterComposer,
          $$PendingSyncTableOrderingComposer,
          $$PendingSyncTableAnnotationComposer,
          $$PendingSyncTableCreateCompanionBuilder,
          $$PendingSyncTableUpdateCompanionBuilder,
          (
            PendingSyncData,
            BaseReferences<_$LocalDb, $PendingSyncTable, PendingSyncData>,
          ),
          PendingSyncData,
          PrefetchHooks Function()
        > {
  $$PendingSyncTableTableManager(_$LocalDb db, $PendingSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingSyncCompanion(
                id: id,
                action: action,
                payloadJson: payloadJson,
                queuedAt: queuedAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String action,
                required String payloadJson,
                required DateTime queuedAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingSyncCompanion.insert(
                id: id,
                action: action,
                payloadJson: payloadJson,
                queuedAt: queuedAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $PendingSyncTable,
      PendingSyncData,
      $$PendingSyncTableFilterComposer,
      $$PendingSyncTableOrderingComposer,
      $$PendingSyncTableAnnotationComposer,
      $$PendingSyncTableCreateCompanionBuilder,
      $$PendingSyncTableUpdateCompanionBuilder,
      (
        PendingSyncData,
        BaseReferences<_$LocalDb, $PendingSyncTable, PendingSyncData>,
      ),
      PendingSyncData,
      PrefetchHooks Function()
    >;

class $LocalDbManager {
  final _$LocalDb _db;
  $LocalDbManager(this._db);
  $$CachedFoodsTableTableManager get cachedFoods =>
      $$CachedFoodsTableTableManager(_db, _db.cachedFoods);
  $$LocalMealLogsTableTableManager get localMealLogs =>
      $$LocalMealLogsTableTableManager(_db, _db.localMealLogs);
  $$FrequentFoodsTableTableManager get frequentFoods =>
      $$FrequentFoodsTableTableManager(_db, _db.frequentFoods);
  $$PendingSyncTableTableManager get pendingSync =>
      $$PendingSyncTableTableManager(_db, _db.pendingSync);
}
