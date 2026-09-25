// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BranchesTable extends Branches with TableInfo<$BranchesTable, Branch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    city,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Branch> instance, {
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
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Branch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Branch(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      city:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}city'],
          )!,
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $BranchesTable createAlias(String alias) {
    return $BranchesTable(attachedDatabase, alias);
  }
}

class Branch extends DataClass implements Insertable<Branch> {
  final String id;
  final String name;
  final String city;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Branch({
    required this.id,
    required this.name,
    required this.city,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['city'] = Variable<String>(city);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BranchesCompanion toCompanion(bool nullToAbsent) {
    return BranchesCompanion(
      id: Value(id),
      name: Value(name),
      city: Value(city),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Branch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Branch(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      city: serializer.fromJson<String>(json['city']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'city': serializer.toJson<String>(city),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? city,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Branch(
    id: id ?? this.id,
    name: name ?? this.name,
    city: city ?? this.city,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Branch copyWithCompanion(BranchesCompanion data) {
    return Branch(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      city: data.city.present ? data.city.value : this.city,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Branch(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, city, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branch &&
          other.id == this.id &&
          other.name == this.name &&
          other.city == this.city &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BranchesCompanion extends UpdateCompanion<Branch> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> city;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BranchesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.city = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchesCompanion.insert({
    required String id,
    required String name,
    required String city,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       city = Value(city);
  static Insertable<Branch> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? city,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (city != null) 'city': city,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? city,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BranchesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolesTable extends Roles with TableInfo<$RolesTable, Role> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Role> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Role map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Role(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $RolesTable createAlias(String alias) {
    return $RolesTable(attachedDatabase, alias);
  }
}

class Role extends DataClass implements Insertable<Role> {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  const Role({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RolesCompanion toCompanion(bool nullToAbsent) {
    return RolesCompanion(
      id: Value(id),
      name: Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory Role.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Role(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Role copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => Role(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  Role copyWithCompanion(RolesCompanion data) {
    return Role(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Role(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Role &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class RolesCompanion extends UpdateCompanion<Role> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RolesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Role> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RolesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
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
    return (StringBuffer('RolesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PermissionsTable extends Permissions
    with TableInfo<$PermissionsTable, Permission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PermissionsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Permission> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Permission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Permission(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $PermissionsTable createAlias(String alias) {
    return $PermissionsTable(attachedDatabase, alias);
  }
}

class Permission extends DataClass implements Insertable<Permission> {
  final String id;
  final String name;
  final String? description;
  const Permission({required this.id, required this.name, this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  PermissionsCompanion toCompanion(bool nullToAbsent) {
    return PermissionsCompanion(
      id: Value(id),
      name: Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
    );
  }

  factory Permission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Permission(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
    };
  }

  Permission copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
  }) => Permission(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
  );
  Permission copyWithCompanion(PermissionsCompanion data) {
    return Permission(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Permission(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Permission &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description);
}

class PermissionsCompanion extends UpdateCompanion<Permission> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> rowid;
  const PermissionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PermissionsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Permission> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PermissionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return PermissionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PermissionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolePermissionsTable extends RolePermissions
    with TableInfo<$RolePermissionsTable, RolePermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolePermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES roles (id)',
    ),
  );
  static const VerificationMeta _permissionIdMeta = const VerificationMeta(
    'permissionId',
  );
  @override
  late final GeneratedColumn<String> permissionId = GeneratedColumn<String>(
    'permission_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES permissions (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [roleId, permissionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RolePermission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('permission_id')) {
      context.handle(
        _permissionIdMeta,
        permissionId.isAcceptableOrUnknown(
          data['permission_id']!,
          _permissionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roleId, permissionId};
  @override
  RolePermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RolePermission(
      roleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role_id'],
          )!,
      permissionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}permission_id'],
          )!,
    );
  }

  @override
  $RolePermissionsTable createAlias(String alias) {
    return $RolePermissionsTable(attachedDatabase, alias);
  }
}

class RolePermission extends DataClass implements Insertable<RolePermission> {
  final String roleId;
  final String permissionId;
  const RolePermission({required this.roleId, required this.permissionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['role_id'] = Variable<String>(roleId);
    map['permission_id'] = Variable<String>(permissionId);
    return map;
  }

  RolePermissionsCompanion toCompanion(bool nullToAbsent) {
    return RolePermissionsCompanion(
      roleId: Value(roleId),
      permissionId: Value(permissionId),
    );
  }

  factory RolePermission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RolePermission(
      roleId: serializer.fromJson<String>(json['roleId']),
      permissionId: serializer.fromJson<String>(json['permissionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roleId': serializer.toJson<String>(roleId),
      'permissionId': serializer.toJson<String>(permissionId),
    };
  }

  RolePermission copyWith({String? roleId, String? permissionId}) =>
      RolePermission(
        roleId: roleId ?? this.roleId,
        permissionId: permissionId ?? this.permissionId,
      );
  RolePermission copyWithCompanion(RolePermissionsCompanion data) {
    return RolePermission(
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      permissionId:
          data.permissionId.present
              ? data.permissionId.value
              : this.permissionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RolePermission(')
          ..write('roleId: $roleId, ')
          ..write('permissionId: $permissionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roleId, permissionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RolePermission &&
          other.roleId == this.roleId &&
          other.permissionId == this.permissionId);
}

class RolePermissionsCompanion extends UpdateCompanion<RolePermission> {
  final Value<String> roleId;
  final Value<String> permissionId;
  final Value<int> rowid;
  const RolePermissionsCompanion({
    this.roleId = const Value.absent(),
    this.permissionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolePermissionsCompanion.insert({
    required String roleId,
    required String permissionId,
    this.rowid = const Value.absent(),
  }) : roleId = Value(roleId),
       permissionId = Value(permissionId);
  static Insertable<RolePermission> custom({
    Expression<String>? roleId,
    Expression<String>? permissionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roleId != null) 'role_id': roleId,
      if (permissionId != null) 'permission_id': permissionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolePermissionsCompanion copyWith({
    Value<String>? roleId,
    Value<String>? permissionId,
    Value<int>? rowid,
  }) {
    return RolePermissionsCompanion(
      roleId: roleId ?? this.roleId,
      permissionId: permissionId ?? this.permissionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (permissionId.present) {
      map['permission_id'] = Variable<String>(permissionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolePermissionsCompanion(')
          ..write('roleId: $roleId, ')
          ..write('permissionId: $permissionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES roles (id)',
    ),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES branches (id)',
    ),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    passwordHash,
    roleId,
    branchId,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
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
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      passwordHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}password_hash'],
          )!,
      roleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role_id'],
          )!,
      branchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}branch_id'],
          )!,
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String roleId;
  final String branchId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.roleId,
    required this.branchId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['role_id'] = Variable<String>(roleId);
    map['branch_id'] = Variable<String>(branchId);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      passwordHash: Value(passwordHash),
      roleId: Value(roleId),
      branchId: Value(branchId),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      roleId: serializer.fromJson<String>(json['roleId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'roleId': serializer.toJson<String>(roleId),
      'branchId': serializer.toJson<String>(branchId),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? roleId,
    String? branchId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    roleId: roleId ?? this.roleId,
    branchId: branchId ?? this.branchId,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      passwordHash:
          data.passwordHash.present
              ? data.passwordHash.value
              : this.passwordHash,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('roleId: $roleId, ')
          ..write('branchId: $branchId, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    passwordHash,
    roleId,
    branchId,
    active,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.roleId == this.roleId &&
          other.branchId == this.branchId &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> roleId;
  final Value<String> branchId;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.roleId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String email,
    required String passwordHash,
    required String roleId,
    required String branchId,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       passwordHash = Value(passwordHash),
       roleId = Value(roleId),
       branchId = Value(branchId);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? roleId,
    Expression<String>? branchId,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (roleId != null) 'role_id': roleId,
      if (branchId != null) 'branch_id': branchId,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? roleId,
    Value<String>? branchId,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      roleId: roleId ?? this.roleId,
      branchId: branchId ?? this.branchId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('roleId: $roleId, ')
          ..write('branchId: $branchId, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UomsTable extends Uoms with TableInfo<$UomsTable, Uom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UomsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, symbol, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'uoms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Uom> instance, {
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
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Uom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Uom(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      symbol:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}symbol'],
          )!,
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $UomsTable createAlias(String alias) {
    return $UomsTable(attachedDatabase, alias);
  }
}

class Uom extends DataClass implements Insertable<Uom> {
  final String id;
  final String name;
  final String symbol;
  final bool active;
  final DateTime createdAt;
  const Uom({
    required this.id,
    required this.name,
    required this.symbol,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UomsCompanion toCompanion(bool nullToAbsent) {
    return UomsCompanion(
      id: Value(id),
      name: Value(name),
      symbol: Value(symbol),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Uom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Uom(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Uom copyWith({
    String? id,
    String? name,
    String? symbol,
    bool? active,
    DateTime? createdAt,
  }) => Uom(
    id: id ?? this.id,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  Uom copyWithCompanion(UomsCompanion data) {
    return Uom(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Uom(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, symbol, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Uom &&
          other.id == this.id &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class UomsCompanion extends UpdateCompanion<Uom> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> symbol;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UomsCompanion.insert({
    required String id,
    required String name,
    required String symbol,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       symbol = Value(symbol);
  static Insertable<Uom> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UomsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? symbol,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      active: active ?? this.active,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('UomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemCategoriesTable extends ItemCategories
    with TableInfo<$ItemCategoriesTable, ItemCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemCategoriesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    active,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemCategory> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemCategory(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $ItemCategoriesTable createAlias(String alias) {
    return $ItemCategoriesTable(attachedDatabase, alias);
  }
}

class ItemCategory extends DataClass implements Insertable<ItemCategory> {
  final String id;
  final String name;
  final String? description;
  final bool active;
  final DateTime createdAt;
  const ItemCategory({
    required this.id,
    required this.name,
    this.description,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ItemCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ItemCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory ItemCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ItemCategory copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? active,
    DateTime? createdAt,
  }) => ItemCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  ItemCategory copyWithCompanion(ItemCategoriesCompanion data) {
    return ItemCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class ItemCategoriesCompanion extends UpdateCompanion<ItemCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ItemCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemCategoriesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ItemCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ItemCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('ItemCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES item_categories (id)',
    ),
  );
  static const VerificationMeta _uomIdMeta = const VerificationMeta('uomId');
  @override
  late final GeneratedColumn<String> uomId = GeneratedColumn<String>(
    'uom_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES uoms (id)',
    ),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockQtyMeta = const VerificationMeta(
    'stockQty',
  );
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reorderLevelMeta = const VerificationMeta(
    'reorderLevel',
  );
  @override
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    barcode,
    categoryId,
    uomId,
    costPrice,
    sellPrice,
    stockQty,
    reorderLevel,
    iconCode,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
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
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('uom_id')) {
      context.handle(
        _uomIdMeta,
        uomId.isAcceptableOrUnknown(data['uom_id']!, _uomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_uomIdMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    }
    if (data.containsKey('stock_qty')) {
      context.handle(
        _stockQtyMeta,
        stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta),
      );
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
        _reorderLevelMeta,
        reorderLevel.isAcceptableOrUnknown(
          data['reorder_level']!,
          _reorderLevelMeta,
        ),
      );
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      categoryId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category_id'],
          )!,
      uomId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}uom_id'],
          )!,
      costPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}cost_price'],
          )!,
      sellPrice:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}sell_price'],
          )!,
      stockQty:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}stock_qty'],
          )!,
      reorderLevel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}reorder_level'],
          )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      ),
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String name;
  final String? barcode;
  final String categoryId;
  final String uomId;
  final double costPrice;
  final double sellPrice;
  final int stockQty;
  final int reorderLevel;
  final String? iconCode;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Item({
    required this.id,
    required this.name,
    this.barcode,
    required this.categoryId,
    required this.uomId,
    required this.costPrice,
    required this.sellPrice,
    required this.stockQty,
    required this.reorderLevel,
    this.iconCode,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['category_id'] = Variable<String>(categoryId);
    map['uom_id'] = Variable<String>(uomId);
    map['cost_price'] = Variable<double>(costPrice);
    map['sell_price'] = Variable<double>(sellPrice);
    map['stock_qty'] = Variable<int>(stockQty);
    map['reorder_level'] = Variable<int>(reorderLevel);
    if (!nullToAbsent || iconCode != null) {
      map['icon_code'] = Variable<String>(iconCode);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      name: Value(name),
      barcode:
          barcode == null && nullToAbsent
              ? const Value.absent()
              : Value(barcode),
      categoryId: Value(categoryId),
      uomId: Value(uomId),
      costPrice: Value(costPrice),
      sellPrice: Value(sellPrice),
      stockQty: Value(stockQty),
      reorderLevel: Value(reorderLevel),
      iconCode:
          iconCode == null && nullToAbsent
              ? const Value.absent()
              : Value(iconCode),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      uomId: serializer.fromJson<String>(json['uomId']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      stockQty: serializer.fromJson<int>(json['stockQty']),
      reorderLevel: serializer.fromJson<int>(json['reorderLevel']),
      iconCode: serializer.fromJson<String?>(json['iconCode']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String?>(barcode),
      'categoryId': serializer.toJson<String>(categoryId),
      'uomId': serializer.toJson<String>(uomId),
      'costPrice': serializer.toJson<double>(costPrice),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'stockQty': serializer.toJson<int>(stockQty),
      'reorderLevel': serializer.toJson<int>(reorderLevel),
      'iconCode': serializer.toJson<String?>(iconCode),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Item copyWith({
    String? id,
    String? name,
    Value<String?> barcode = const Value.absent(),
    String? categoryId,
    String? uomId,
    double? costPrice,
    double? sellPrice,
    int? stockQty,
    int? reorderLevel,
    Value<String?> iconCode = const Value.absent(),
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Item(
    id: id ?? this.id,
    name: name ?? this.name,
    barcode: barcode.present ? barcode.value : this.barcode,
    categoryId: categoryId ?? this.categoryId,
    uomId: uomId ?? this.uomId,
    costPrice: costPrice ?? this.costPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    stockQty: stockQty ?? this.stockQty,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    iconCode: iconCode.present ? iconCode.value : this.iconCode,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      uomId: data.uomId.present ? data.uomId.value : this.uomId,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      reorderLevel:
          data.reorderLevel.present
              ? data.reorderLevel.value
              : this.reorderLevel,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('uomId: $uomId, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('iconCode: $iconCode, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    barcode,
    categoryId,
    uomId,
    costPrice,
    sellPrice,
    stockQty,
    reorderLevel,
    iconCode,
    active,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.categoryId == this.categoryId &&
          other.uomId == this.uomId &&
          other.costPrice == this.costPrice &&
          other.sellPrice == this.sellPrice &&
          other.stockQty == this.stockQty &&
          other.reorderLevel == this.reorderLevel &&
          other.iconCode == this.iconCode &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> barcode;
  final Value<String> categoryId;
  final Value<String> uomId;
  final Value<double> costPrice;
  final Value<double> sellPrice;
  final Value<int> stockQty;
  final Value<int> reorderLevel;
  final Value<String?> iconCode;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.uomId = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String name,
    this.barcode = const Value.absent(),
    required String categoryId,
    required String uomId,
    this.costPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       categoryId = Value(categoryId),
       uomId = Value(uomId);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<String>? categoryId,
    Expression<String>? uomId,
    Expression<double>? costPrice,
    Expression<double>? sellPrice,
    Expression<int>? stockQty,
    Expression<int>? reorderLevel,
    Expression<String>? iconCode,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (categoryId != null) 'category_id': categoryId,
      if (uomId != null) 'uom_id': uomId,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (stockQty != null) 'stock_qty': stockQty,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (iconCode != null) 'icon_code': iconCode,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? barcode,
    Value<String>? categoryId,
    Value<String>? uomId,
    Value<double>? costPrice,
    Value<double>? sellPrice,
    Value<int>? stockQty,
    Value<int>? reorderLevel,
    Value<String?>? iconCode,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      uomId: uomId ?? this.uomId,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stockQty: stockQty ?? this.stockQty,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      iconCode: iconCode ?? this.iconCode,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (uomId.present) {
      map['uom_id'] = Variable<String>(uomId.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<int>(reorderLevel.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('uomId: $uomId, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('iconCode: $iconCode, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceListsTable extends PriceLists
    with TableInfo<$PriceListsTable, PriceList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceListsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LYD'),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, currency, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceList> instance, {
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
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceList(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      currency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}currency'],
          )!,
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $PriceListsTable createAlias(String alias) {
    return $PriceListsTable(attachedDatabase, alias);
  }
}

class PriceList extends DataClass implements Insertable<PriceList> {
  final String id;
  final String name;
  final String currency;
  final bool active;
  final DateTime createdAt;
  const PriceList({
    required this.id,
    required this.name,
    required this.currency,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PriceListsCompanion toCompanion(bool nullToAbsent) {
    return PriceListsCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory PriceList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PriceList copyWith({
    String? id,
    String? name,
    String? currency,
    bool? active,
    DateTime? createdAt,
  }) => PriceList(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  PriceList copyWithCompanion(PriceListsCompanion data) {
    return PriceList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, currency, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceList &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class PriceListsCompanion extends UpdateCompanion<PriceList> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PriceListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceListsCompanion.insert({
    required String id,
    required String name,
    this.currency = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PriceList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PriceListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      active: active ?? this.active,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('PriceListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceListItemsTable extends PriceListItems
    with TableInfo<$PriceListItemsTable, PriceListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _priceListIdMeta = const VerificationMeta(
    'priceListId',
  );
  @override
  late final GeneratedColumn<String> priceListId = GeneratedColumn<String>(
    'price_list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES price_lists (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [priceListId, itemId, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('price_list_id')) {
      context.handle(
        _priceListIdMeta,
        priceListId.isAcceptableOrUnknown(
          data['price_list_id']!,
          _priceListIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceListIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {priceListId, itemId};
  @override
  PriceListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceListItem(
      priceListId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}price_list_id'],
          )!,
      itemId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}item_id'],
          )!,
      price:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}price'],
          )!,
    );
  }

  @override
  $PriceListItemsTable createAlias(String alias) {
    return $PriceListItemsTable(attachedDatabase, alias);
  }
}

class PriceListItem extends DataClass implements Insertable<PriceListItem> {
  final String priceListId;
  final String itemId;
  final double price;
  const PriceListItem({
    required this.priceListId,
    required this.itemId,
    required this.price,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['price_list_id'] = Variable<String>(priceListId);
    map['item_id'] = Variable<String>(itemId);
    map['price'] = Variable<double>(price);
    return map;
  }

  PriceListItemsCompanion toCompanion(bool nullToAbsent) {
    return PriceListItemsCompanion(
      priceListId: Value(priceListId),
      itemId: Value(itemId),
      price: Value(price),
    );
  }

  factory PriceListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceListItem(
      priceListId: serializer.fromJson<String>(json['priceListId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      price: serializer.fromJson<double>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'priceListId': serializer.toJson<String>(priceListId),
      'itemId': serializer.toJson<String>(itemId),
      'price': serializer.toJson<double>(price),
    };
  }

  PriceListItem copyWith({
    String? priceListId,
    String? itemId,
    double? price,
  }) => PriceListItem(
    priceListId: priceListId ?? this.priceListId,
    itemId: itemId ?? this.itemId,
    price: price ?? this.price,
  );
  PriceListItem copyWithCompanion(PriceListItemsCompanion data) {
    return PriceListItem(
      priceListId:
          data.priceListId.present ? data.priceListId.value : this.priceListId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceListItem(')
          ..write('priceListId: $priceListId, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(priceListId, itemId, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceListItem &&
          other.priceListId == this.priceListId &&
          other.itemId == this.itemId &&
          other.price == this.price);
}

class PriceListItemsCompanion extends UpdateCompanion<PriceListItem> {
  final Value<String> priceListId;
  final Value<String> itemId;
  final Value<double> price;
  final Value<int> rowid;
  const PriceListItemsCompanion({
    this.priceListId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.price = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceListItemsCompanion.insert({
    required String priceListId,
    required String itemId,
    required double price,
    this.rowid = const Value.absent(),
  }) : priceListId = Value(priceListId),
       itemId = Value(itemId),
       price = Value(price);
  static Insertable<PriceListItem> custom({
    Expression<String>? priceListId,
    Expression<String>? itemId,
    Expression<double>? price,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (priceListId != null) 'price_list_id': priceListId,
      if (itemId != null) 'item_id': itemId,
      if (price != null) 'price': price,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceListItemsCompanion copyWith({
    Value<String>? priceListId,
    Value<String>? itemId,
    Value<double>? price,
    Value<int>? rowid,
  }) {
    return PriceListItemsCompanion(
      priceListId: priceListId ?? this.priceListId,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (priceListId.present) {
      map['price_list_id'] = Variable<String>(priceListId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceListItemsCompanion(')
          ..write('priceListId: $priceListId, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WarehousesTable extends Warehouses
    with TableInfo<$WarehousesTable, Warehouse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarehousesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES branches (id)',
    ),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, branchId, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warehouses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Warehouse> instance, {
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
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Warehouse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Warehouse(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      branchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}branch_id'],
          )!,
      active:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}active'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $WarehousesTable createAlias(String alias) {
    return $WarehousesTable(attachedDatabase, alias);
  }
}

class Warehouse extends DataClass implements Insertable<Warehouse> {
  final String id;
  final String name;
  final String branchId;
  final bool active;
  final DateTime createdAt;
  const Warehouse({
    required this.id,
    required this.name,
    required this.branchId,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['branch_id'] = Variable<String>(branchId);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WarehousesCompanion toCompanion(bool nullToAbsent) {
    return WarehousesCompanion(
      id: Value(id),
      name: Value(name),
      branchId: Value(branchId),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Warehouse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Warehouse(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      branchId: serializer.fromJson<String>(json['branchId']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'branchId': serializer.toJson<String>(branchId),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Warehouse copyWith({
    String? id,
    String? name,
    String? branchId,
    bool? active,
    DateTime? createdAt,
  }) => Warehouse(
    id: id ?? this.id,
    name: name ?? this.name,
    branchId: branchId ?? this.branchId,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  Warehouse copyWithCompanion(WarehousesCompanion data) {
    return Warehouse(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Warehouse(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('branchId: $branchId, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, branchId, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Warehouse &&
          other.id == this.id &&
          other.name == this.name &&
          other.branchId == this.branchId &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class WarehousesCompanion extends UpdateCompanion<Warehouse> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> branchId;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WarehousesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.branchId = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarehousesCompanion.insert({
    required String id,
    required String name,
    required String branchId,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       branchId = Value(branchId);
  static Insertable<Warehouse> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? branchId,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (branchId != null) 'branch_id': branchId,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarehousesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? branchId,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WarehousesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      branchId: branchId ?? this.branchId,
      active: active ?? this.active,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('WarehousesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('branchId: $branchId, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockLedgerEntriesTable extends StockLedgerEntries
    with TableInfo<$StockLedgerEntriesTable, StockLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _warehouseIdMeta = const VerificationMeta(
    'warehouseId',
  );
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
    'warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES warehouses (id)',
    ),
  );
  static const VerificationMeta _qtyChangeMeta = const VerificationMeta(
    'qtyChange',
  );
  @override
  late final GeneratedColumn<double> qtyChange = GeneratedColumn<double>(
    'qty_change',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterMeta = const VerificationMeta(
    'balanceAfter',
  );
  @override
  late final GeneratedColumn<double> balanceAfter = GeneratedColumn<double>(
    'balance_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voucherTypeMeta = const VerificationMeta(
    'voucherType',
  );
  @override
  late final GeneratedColumn<String> voucherType = GeneratedColumn<String>(
    'voucher_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voucherIdMeta = const VerificationMeta(
    'voucherId',
  );
  @override
  late final GeneratedColumn<String> voucherId = GeneratedColumn<String>(
    'voucher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchNoMeta = const VerificationMeta(
    'batchNo',
  );
  @override
  late final GeneratedColumn<String> batchNo = GeneratedColumn<String>(
    'batch_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reversalOfMeta = const VerificationMeta(
    'reversalOf',
  );
  @override
  late final GeneratedColumn<String> reversalOf = GeneratedColumn<String>(
    'reversal_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postingDateMeta = const VerificationMeta(
    'postingDate',
  );
  @override
  late final GeneratedColumn<DateTime> postingDate = GeneratedColumn<DateTime>(
    'posting_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    warehouseId,
    qtyChange,
    balanceAfter,
    voucherType,
    voucherId,
    batchNo,
    reversalOf,
    reason,
    postingDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
        _warehouseIdMeta,
        warehouseId.isAcceptableOrUnknown(
          data['warehouse_id']!,
          _warehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('qty_change')) {
      context.handle(
        _qtyChangeMeta,
        qtyChange.isAcceptableOrUnknown(data['qty_change']!, _qtyChangeMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyChangeMeta);
    }
    if (data.containsKey('balance_after')) {
      context.handle(
        _balanceAfterMeta,
        balanceAfter.isAcceptableOrUnknown(
          data['balance_after']!,
          _balanceAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterMeta);
    }
    if (data.containsKey('voucher_type')) {
      context.handle(
        _voucherTypeMeta,
        voucherType.isAcceptableOrUnknown(
          data['voucher_type']!,
          _voucherTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voucherTypeMeta);
    }
    if (data.containsKey('voucher_id')) {
      context.handle(
        _voucherIdMeta,
        voucherId.isAcceptableOrUnknown(data['voucher_id']!, _voucherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_voucherIdMeta);
    }
    if (data.containsKey('batch_no')) {
      context.handle(
        _batchNoMeta,
        batchNo.isAcceptableOrUnknown(data['batch_no']!, _batchNoMeta),
      );
    }
    if (data.containsKey('reversal_of')) {
      context.handle(
        _reversalOfMeta,
        reversalOf.isAcceptableOrUnknown(data['reversal_of']!, _reversalOfMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('posting_date')) {
      context.handle(
        _postingDateMeta,
        postingDate.isAcceptableOrUnknown(
          data['posting_date']!,
          _postingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_postingDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLedgerEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      itemId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}item_id'],
          )!,
      warehouseId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}warehouse_id'],
          )!,
      qtyChange:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}qty_change'],
          )!,
      balanceAfter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}balance_after'],
          )!,
      voucherType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}voucher_type'],
          )!,
      voucherId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}voucher_id'],
          )!,
      batchNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_no'],
      ),
      reversalOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reversal_of'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      postingDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}posting_date'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $StockLedgerEntriesTable createAlias(String alias) {
    return $StockLedgerEntriesTable(attachedDatabase, alias);
  }
}

class StockLedgerEntry extends DataClass
    implements Insertable<StockLedgerEntry> {
  final String id;
  final String itemId;
  final String warehouseId;
  final double qtyChange;
  final double balanceAfter;
  final String voucherType;
  final String voucherId;
  final String? batchNo;
  final String? reversalOf;
  final String? reason;
  final DateTime postingDate;
  final DateTime createdAt;
  const StockLedgerEntry({
    required this.id,
    required this.itemId,
    required this.warehouseId,
    required this.qtyChange,
    required this.balanceAfter,
    required this.voucherType,
    required this.voucherId,
    this.batchNo,
    this.reversalOf,
    this.reason,
    required this.postingDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['qty_change'] = Variable<double>(qtyChange);
    map['balance_after'] = Variable<double>(balanceAfter);
    map['voucher_type'] = Variable<String>(voucherType);
    map['voucher_id'] = Variable<String>(voucherId);
    if (!nullToAbsent || batchNo != null) {
      map['batch_no'] = Variable<String>(batchNo);
    }
    if (!nullToAbsent || reversalOf != null) {
      map['reversal_of'] = Variable<String>(reversalOf);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['posting_date'] = Variable<DateTime>(postingDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockLedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return StockLedgerEntriesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      warehouseId: Value(warehouseId),
      qtyChange: Value(qtyChange),
      balanceAfter: Value(balanceAfter),
      voucherType: Value(voucherType),
      voucherId: Value(voucherId),
      batchNo:
          batchNo == null && nullToAbsent
              ? const Value.absent()
              : Value(batchNo),
      reversalOf:
          reversalOf == null && nullToAbsent
              ? const Value.absent()
              : Value(reversalOf),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      postingDate: Value(postingDate),
      createdAt: Value(createdAt),
    );
  }

  factory StockLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      qtyChange: serializer.fromJson<double>(json['qtyChange']),
      balanceAfter: serializer.fromJson<double>(json['balanceAfter']),
      voucherType: serializer.fromJson<String>(json['voucherType']),
      voucherId: serializer.fromJson<String>(json['voucherId']),
      batchNo: serializer.fromJson<String?>(json['batchNo']),
      reversalOf: serializer.fromJson<String?>(json['reversalOf']),
      reason: serializer.fromJson<String?>(json['reason']),
      postingDate: serializer.fromJson<DateTime>(json['postingDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'qtyChange': serializer.toJson<double>(qtyChange),
      'balanceAfter': serializer.toJson<double>(balanceAfter),
      'voucherType': serializer.toJson<String>(voucherType),
      'voucherId': serializer.toJson<String>(voucherId),
      'batchNo': serializer.toJson<String?>(batchNo),
      'reversalOf': serializer.toJson<String?>(reversalOf),
      'reason': serializer.toJson<String?>(reason),
      'postingDate': serializer.toJson<DateTime>(postingDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockLedgerEntry copyWith({
    String? id,
    String? itemId,
    String? warehouseId,
    double? qtyChange,
    double? balanceAfter,
    String? voucherType,
    String? voucherId,
    Value<String?> batchNo = const Value.absent(),
    Value<String?> reversalOf = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    DateTime? postingDate,
    DateTime? createdAt,
  }) => StockLedgerEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    warehouseId: warehouseId ?? this.warehouseId,
    qtyChange: qtyChange ?? this.qtyChange,
    balanceAfter: balanceAfter ?? this.balanceAfter,
    voucherType: voucherType ?? this.voucherType,
    voucherId: voucherId ?? this.voucherId,
    batchNo: batchNo.present ? batchNo.value : this.batchNo,
    reversalOf: reversalOf.present ? reversalOf.value : this.reversalOf,
    reason: reason.present ? reason.value : this.reason,
    postingDate: postingDate ?? this.postingDate,
    createdAt: createdAt ?? this.createdAt,
  );
  StockLedgerEntry copyWithCompanion(StockLedgerEntriesCompanion data) {
    return StockLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      warehouseId:
          data.warehouseId.present ? data.warehouseId.value : this.warehouseId,
      qtyChange: data.qtyChange.present ? data.qtyChange.value : this.qtyChange,
      balanceAfter:
          data.balanceAfter.present
              ? data.balanceAfter.value
              : this.balanceAfter,
      voucherType:
          data.voucherType.present ? data.voucherType.value : this.voucherType,
      voucherId: data.voucherId.present ? data.voucherId.value : this.voucherId,
      batchNo: data.batchNo.present ? data.batchNo.value : this.batchNo,
      reversalOf:
          data.reversalOf.present ? data.reversalOf.value : this.reversalOf,
      reason: data.reason.present ? data.reason.value : this.reason,
      postingDate:
          data.postingDate.present ? data.postingDate.value : this.postingDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLedgerEntry(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('qtyChange: $qtyChange, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('voucherType: $voucherType, ')
          ..write('voucherId: $voucherId, ')
          ..write('batchNo: $batchNo, ')
          ..write('reversalOf: $reversalOf, ')
          ..write('reason: $reason, ')
          ..write('postingDate: $postingDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    warehouseId,
    qtyChange,
    balanceAfter,
    voucherType,
    voucherId,
    batchNo,
    reversalOf,
    reason,
    postingDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLedgerEntry &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.warehouseId == this.warehouseId &&
          other.qtyChange == this.qtyChange &&
          other.balanceAfter == this.balanceAfter &&
          other.voucherType == this.voucherType &&
          other.voucherId == this.voucherId &&
          other.batchNo == this.batchNo &&
          other.reversalOf == this.reversalOf &&
          other.reason == this.reason &&
          other.postingDate == this.postingDate &&
          other.createdAt == this.createdAt);
}

class StockLedgerEntriesCompanion extends UpdateCompanion<StockLedgerEntry> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> warehouseId;
  final Value<double> qtyChange;
  final Value<double> balanceAfter;
  final Value<String> voucherType;
  final Value<String> voucherId;
  final Value<String?> batchNo;
  final Value<String?> reversalOf;
  final Value<String?> reason;
  final Value<DateTime> postingDate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StockLedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.qtyChange = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.voucherType = const Value.absent(),
    this.voucherId = const Value.absent(),
    this.batchNo = const Value.absent(),
    this.reversalOf = const Value.absent(),
    this.reason = const Value.absent(),
    this.postingDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockLedgerEntriesCompanion.insert({
    required String id,
    required String itemId,
    required String warehouseId,
    required double qtyChange,
    required double balanceAfter,
    required String voucherType,
    required String voucherId,
    this.batchNo = const Value.absent(),
    this.reversalOf = const Value.absent(),
    this.reason = const Value.absent(),
    required DateTime postingDate,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       warehouseId = Value(warehouseId),
       qtyChange = Value(qtyChange),
       balanceAfter = Value(balanceAfter),
       voucherType = Value(voucherType),
       voucherId = Value(voucherId),
       postingDate = Value(postingDate);
  static Insertable<StockLedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? warehouseId,
    Expression<double>? qtyChange,
    Expression<double>? balanceAfter,
    Expression<String>? voucherType,
    Expression<String>? voucherId,
    Expression<String>? batchNo,
    Expression<String>? reversalOf,
    Expression<String>? reason,
    Expression<DateTime>? postingDate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (qtyChange != null) 'qty_change': qtyChange,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (voucherType != null) 'voucher_type': voucherType,
      if (voucherId != null) 'voucher_id': voucherId,
      if (batchNo != null) 'batch_no': batchNo,
      if (reversalOf != null) 'reversal_of': reversalOf,
      if (reason != null) 'reason': reason,
      if (postingDate != null) 'posting_date': postingDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockLedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? warehouseId,
    Value<double>? qtyChange,
    Value<double>? balanceAfter,
    Value<String>? voucherType,
    Value<String>? voucherId,
    Value<String?>? batchNo,
    Value<String?>? reversalOf,
    Value<String?>? reason,
    Value<DateTime>? postingDate,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StockLedgerEntriesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      warehouseId: warehouseId ?? this.warehouseId,
      qtyChange: qtyChange ?? this.qtyChange,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      voucherType: voucherType ?? this.voucherType,
      voucherId: voucherId ?? this.voucherId,
      batchNo: batchNo ?? this.batchNo,
      reversalOf: reversalOf ?? this.reversalOf,
      reason: reason ?? this.reason,
      postingDate: postingDate ?? this.postingDate,
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
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (qtyChange.present) {
      map['qty_change'] = Variable<double>(qtyChange.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<double>(balanceAfter.value);
    }
    if (voucherType.present) {
      map['voucher_type'] = Variable<String>(voucherType.value);
    }
    if (voucherId.present) {
      map['voucher_id'] = Variable<String>(voucherId.value);
    }
    if (batchNo.present) {
      map['batch_no'] = Variable<String>(batchNo.value);
    }
    if (reversalOf.present) {
      map['reversal_of'] = Variable<String>(reversalOf.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (postingDate.present) {
      map['posting_date'] = Variable<DateTime>(postingDate.value);
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
    return (StringBuffer('StockLedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('qtyChange: $qtyChange, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('voucherType: $voucherType, ')
          ..write('voucherId: $voucherId, ')
          ..write('batchNo: $batchNo, ')
          ..write('reversalOf: $reversalOf, ')
          ..write('reason: $reason, ')
          ..write('postingDate: $postingDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LicensesTable extends Licenses
    with TableInfo<$LicensesTable, LicenseRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LicensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planCodeMeta = const VerificationMeta(
    'planCode',
  );
  @override
  late final GeneratedColumn<String> planCode = GeneratedColumn<String>(
    'plan_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activatedAtMeta = const VerificationMeta(
    'activatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
    'activated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    customerName,
    fingerprint,
    planCode,
    issuedAt,
    expiresAt,
    activatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'licenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LicenseRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('plan_code')) {
      context.handle(
        _planCodeMeta,
        planCode.isAcceptableOrUnknown(data['plan_code']!, _planCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_planCodeMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
        _activatedAtMeta,
        activatedAt.isAcceptableOrUnknown(
          data['activated_at']!,
          _activatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LicenseRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LicenseRecord(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      code:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}code'],
          )!,
      customerName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}customer_name'],
          )!,
      fingerprint:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fingerprint'],
          )!,
      planCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}plan_code'],
          )!,
      issuedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}issued_at'],
          )!,
      expiresAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}expires_at'],
          )!,
      activatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}activated_at'],
          )!,
    );
  }

  @override
  $LicensesTable createAlias(String alias) {
    return $LicensesTable(attachedDatabase, alias);
  }
}

class LicenseRecord extends DataClass implements Insertable<LicenseRecord> {
  final String id;
  final String code;
  final String customerName;
  final String fingerprint;
  final String planCode;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime activatedAt;
  const LicenseRecord({
    required this.id,
    required this.code,
    required this.customerName,
    required this.fingerprint,
    required this.planCode,
    required this.issuedAt,
    required this.expiresAt,
    required this.activatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['customer_name'] = Variable<String>(customerName);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['plan_code'] = Variable<String>(planCode);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['activated_at'] = Variable<DateTime>(activatedAt);
    return map;
  }

  LicensesCompanion toCompanion(bool nullToAbsent) {
    return LicensesCompanion(
      id: Value(id),
      code: Value(code),
      customerName: Value(customerName),
      fingerprint: Value(fingerprint),
      planCode: Value(planCode),
      issuedAt: Value(issuedAt),
      expiresAt: Value(expiresAt),
      activatedAt: Value(activatedAt),
    );
  }

  factory LicenseRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LicenseRecord(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      customerName: serializer.fromJson<String>(json['customerName']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      planCode: serializer.fromJson<String>(json['planCode']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      activatedAt: serializer.fromJson<DateTime>(json['activatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'customerName': serializer.toJson<String>(customerName),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'planCode': serializer.toJson<String>(planCode),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'activatedAt': serializer.toJson<DateTime>(activatedAt),
    };
  }

  LicenseRecord copyWith({
    String? id,
    String? code,
    String? customerName,
    String? fingerprint,
    String? planCode,
    DateTime? issuedAt,
    DateTime? expiresAt,
    DateTime? activatedAt,
  }) => LicenseRecord(
    id: id ?? this.id,
    code: code ?? this.code,
    customerName: customerName ?? this.customerName,
    fingerprint: fingerprint ?? this.fingerprint,
    planCode: planCode ?? this.planCode,
    issuedAt: issuedAt ?? this.issuedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    activatedAt: activatedAt ?? this.activatedAt,
  );
  LicenseRecord copyWithCompanion(LicensesCompanion data) {
    return LicenseRecord(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      customerName:
          data.customerName.present
              ? data.customerName.value
              : this.customerName,
      fingerprint:
          data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      planCode: data.planCode.present ? data.planCode.value : this.planCode,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      activatedAt:
          data.activatedAt.present ? data.activatedAt.value : this.activatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LicenseRecord(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('customerName: $customerName, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('planCode: $planCode, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('activatedAt: $activatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    customerName,
    fingerprint,
    planCode,
    issuedAt,
    expiresAt,
    activatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LicenseRecord &&
          other.id == this.id &&
          other.code == this.code &&
          other.customerName == this.customerName &&
          other.fingerprint == this.fingerprint &&
          other.planCode == this.planCode &&
          other.issuedAt == this.issuedAt &&
          other.expiresAt == this.expiresAt &&
          other.activatedAt == this.activatedAt);
}

class LicensesCompanion extends UpdateCompanion<LicenseRecord> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> customerName;
  final Value<String> fingerprint;
  final Value<String> planCode;
  final Value<DateTime> issuedAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime> activatedAt;
  final Value<int> rowid;
  const LicensesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.customerName = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.planCode = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LicensesCompanion.insert({
    required String id,
    required String code,
    required String customerName,
    required String fingerprint,
    required String planCode,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required DateTime activatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       customerName = Value(customerName),
       fingerprint = Value(fingerprint),
       planCode = Value(planCode),
       issuedAt = Value(issuedAt),
       expiresAt = Value(expiresAt),
       activatedAt = Value(activatedAt);
  static Insertable<LicenseRecord> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? customerName,
    Expression<String>? fingerprint,
    Expression<String>? planCode,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? activatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (customerName != null) 'customer_name': customerName,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (planCode != null) 'plan_code': planCode,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LicensesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? customerName,
    Value<String>? fingerprint,
    Value<String>? planCode,
    Value<DateTime>? issuedAt,
    Value<DateTime>? expiresAt,
    Value<DateTime>? activatedAt,
    Value<int>? rowid,
  }) {
    return LicensesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      customerName: customerName ?? this.customerName,
      fingerprint: fingerprint ?? this.fingerprint,
      planCode: planCode ?? this.planCode,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      activatedAt: activatedAt ?? this.activatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (planCode.present) {
      map['plan_code'] = Variable<String>(planCode.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LicensesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('customerName: $customerName, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('planCode: $planCode, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BranchesTable branches = $BranchesTable(this);
  late final $RolesTable roles = $RolesTable(this);
  late final $PermissionsTable permissions = $PermissionsTable(this);
  late final $RolePermissionsTable rolePermissions = $RolePermissionsTable(
    this,
  );
  late final $UsersTable users = $UsersTable(this);
  late final $UomsTable uoms = $UomsTable(this);
  late final $ItemCategoriesTable itemCategories = $ItemCategoriesTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $PriceListsTable priceLists = $PriceListsTable(this);
  late final $PriceListItemsTable priceListItems = $PriceListItemsTable(this);
  late final $WarehousesTable warehouses = $WarehousesTable(this);
  late final $StockLedgerEntriesTable stockLedgerEntries =
      $StockLedgerEntriesTable(this);
  late final $LicensesTable licenses = $LicensesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    branches,
    roles,
    permissions,
    rolePermissions,
    users,
    uoms,
    itemCategories,
    items,
    priceLists,
    priceListItems,
    warehouses,
    stockLedgerEntries,
    licenses,
  ];
}

typedef $$BranchesTableCreateCompanionBuilder =
    BranchesCompanion Function({
      required String id,
      required String name,
      required String city,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BranchesTableUpdateCompanionBuilder =
    BranchesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> city,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BranchesTableReferences
    extends BaseReferences<_$AppDatabase, $BranchesTable, Branch> {
  $$BranchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UsersTable, List<User>> _usersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.users,
    aliasName: $_aliasNameGenerator(db.branches.id, db.users.branchId),
  );

  $$UsersTableProcessedTableManager get usersRefs {
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WarehousesTable, List<Warehouse>>
  _warehousesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.warehouses,
    aliasName: $_aliasNameGenerator(db.branches.id, db.warehouses.branchId),
  );

  $$WarehousesTableProcessedTableManager get warehousesRefs {
    final manager = $$WarehousesTableTableManager(
      $_db,
      $_db.warehouses,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_warehousesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BranchesTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableFilterComposer({
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

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> usersRefs(
    Expression<bool> Function($$UsersTableFilterComposer f) f,
  ) {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> warehousesRefs(
    Expression<bool> Function($$WarehousesTableFilterComposer f) f,
  ) {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warehouses,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableFilterComposer(
            $db: $db,
            $table: $db.warehouses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableOrderingComposer({
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

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableAnnotationComposer({
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

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> usersRefs<T extends Object>(
    Expression<T> Function($$UsersTableAnnotationComposer a) f,
  ) {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> warehousesRefs<T extends Object>(
    Expression<T> Function($$WarehousesTableAnnotationComposer a) f,
  ) {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warehouses,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableAnnotationComposer(
            $db: $db,
            $table: $db.warehouses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BranchesTable,
          Branch,
          $$BranchesTableFilterComposer,
          $$BranchesTableOrderingComposer,
          $$BranchesTableAnnotationComposer,
          $$BranchesTableCreateCompanionBuilder,
          $$BranchesTableUpdateCompanionBuilder,
          (Branch, $$BranchesTableReferences),
          Branch,
          PrefetchHooks Function({bool usersRefs, bool warehousesRefs})
        > {
  $$BranchesTableTableManager(_$AppDatabase db, $BranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$BranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesCompanion(
                id: id,
                name: name,
                city: city,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String city,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesCompanion.insert(
                id: id,
                name: name,
                city: city,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$BranchesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({usersRefs = false, warehousesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (usersRefs) db.users,
                if (warehousesRefs) db.warehouses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (usersRefs)
                    await $_getPrefetchedData<Branch, $BranchesTable, User>(
                      currentTable: table,
                      referencedTable: $$BranchesTableReferences
                          ._usersRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$BranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).usersRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.branchId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (warehousesRefs)
                    await $_getPrefetchedData<
                      Branch,
                      $BranchesTable,
                      Warehouse
                    >(
                      currentTable: table,
                      referencedTable: $$BranchesTableReferences
                          ._warehousesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$BranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).warehousesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.branchId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BranchesTable,
      Branch,
      $$BranchesTableFilterComposer,
      $$BranchesTableOrderingComposer,
      $$BranchesTableAnnotationComposer,
      $$BranchesTableCreateCompanionBuilder,
      $$BranchesTableUpdateCompanionBuilder,
      (Branch, $$BranchesTableReferences),
      Branch,
      PrefetchHooks Function({bool usersRefs, bool warehousesRefs})
    >;
typedef $$RolesTableCreateCompanionBuilder =
    RolesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RolesTableUpdateCompanionBuilder =
    RolesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RolesTableReferences
    extends BaseReferences<_$AppDatabase, $RolesTable, Role> {
  $$RolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RolePermissionsTable, List<RolePermission>>
  _rolePermissionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rolePermissions,
    aliasName: $_aliasNameGenerator(db.roles.id, db.rolePermissions.roleId),
  );

  $$RolePermissionsTableProcessedTableManager get rolePermissionsRefs {
    final manager = $$RolePermissionsTableTableManager(
      $_db,
      $_db.rolePermissions,
    ).filter((f) => f.roleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rolePermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UsersTable, List<User>> _usersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.users,
    aliasName: $_aliasNameGenerator(db.roles.id, db.users.roleId),
  );

  $$UsersTableProcessedTableManager get usersRefs {
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.roleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RolesTableFilterComposer extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> rolePermissionsRefs(
    Expression<bool> Function($$RolePermissionsTableFilterComposer f) f,
  ) {
    final $$RolePermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rolePermissions,
      getReferencedColumn: (t) => t.roleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolePermissionsTableFilterComposer(
            $db: $db,
            $table: $db.rolePermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> usersRefs(
    Expression<bool> Function($$UsersTableFilterComposer f) f,
  ) {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.roleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RolesTableOrderingComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> rolePermissionsRefs<T extends Object>(
    Expression<T> Function($$RolePermissionsTableAnnotationComposer a) f,
  ) {
    final $$RolePermissionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rolePermissions,
      getReferencedColumn: (t) => t.roleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolePermissionsTableAnnotationComposer(
            $db: $db,
            $table: $db.rolePermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> usersRefs<T extends Object>(
    Expression<T> Function($$UsersTableAnnotationComposer a) f,
  ) {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.roleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolesTable,
          Role,
          $$RolesTableFilterComposer,
          $$RolesTableOrderingComposer,
          $$RolesTableAnnotationComposer,
          $$RolesTableCreateCompanionBuilder,
          $$RolesTableUpdateCompanionBuilder,
          (Role, $$RolesTableReferences),
          Role,
          PrefetchHooks Function({bool rolePermissionsRefs, bool usersRefs})
        > {
  $$RolesTableTableManager(_$AppDatabase db, $RolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RolesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            rolePermissionsRefs = false,
            usersRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rolePermissionsRefs) db.rolePermissions,
                if (usersRefs) db.users,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rolePermissionsRefs)
                    await $_getPrefetchedData<
                      Role,
                      $RolesTable,
                      RolePermission
                    >(
                      currentTable: table,
                      referencedTable: $$RolesTableReferences
                          ._rolePermissionsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$RolesTableReferences(
                                db,
                                table,
                                p0,
                              ).rolePermissionsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.roleId == item.id),
                      typedResults: items,
                    ),
                  if (usersRefs)
                    await $_getPrefetchedData<Role, $RolesTable, User>(
                      currentTable: table,
                      referencedTable: $$RolesTableReferences._usersRefsTable(
                        db,
                      ),
                      managerFromTypedResult:
                          (p0) =>
                              $$RolesTableReferences(db, table, p0).usersRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.roleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolesTable,
      Role,
      $$RolesTableFilterComposer,
      $$RolesTableOrderingComposer,
      $$RolesTableAnnotationComposer,
      $$RolesTableCreateCompanionBuilder,
      $$RolesTableUpdateCompanionBuilder,
      (Role, $$RolesTableReferences),
      Role,
      PrefetchHooks Function({bool rolePermissionsRefs, bool usersRefs})
    >;
typedef $$PermissionsTableCreateCompanionBuilder =
    PermissionsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$PermissionsTableUpdateCompanionBuilder =
    PermissionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int> rowid,
    });

final class $$PermissionsTableReferences
    extends BaseReferences<_$AppDatabase, $PermissionsTable, Permission> {
  $$PermissionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RolePermissionsTable, List<RolePermission>>
  _rolePermissionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rolePermissions,
    aliasName: $_aliasNameGenerator(
      db.permissions.id,
      db.rolePermissions.permissionId,
    ),
  );

  $$RolePermissionsTableProcessedTableManager get rolePermissionsRefs {
    final manager = $$RolePermissionsTableTableManager(
      $_db,
      $_db.rolePermissions,
    ).filter((f) => f.permissionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rolePermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> rolePermissionsRefs(
    Expression<bool> Function($$RolePermissionsTableFilterComposer f) f,
  ) {
    final $$RolePermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rolePermissions,
      getReferencedColumn: (t) => t.permissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolePermissionsTableFilterComposer(
            $db: $db,
            $table: $db.rolePermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PermissionsTable> {
  $$PermissionsTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  Expression<T> rolePermissionsRefs<T extends Object>(
    Expression<T> Function($$RolePermissionsTableAnnotationComposer a) f,
  ) {
    final $$RolePermissionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rolePermissions,
      getReferencedColumn: (t) => t.permissionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolePermissionsTableAnnotationComposer(
            $db: $db,
            $table: $db.rolePermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PermissionsTable,
          Permission,
          $$PermissionsTableFilterComposer,
          $$PermissionsTableOrderingComposer,
          $$PermissionsTableAnnotationComposer,
          $$PermissionsTableCreateCompanionBuilder,
          $$PermissionsTableUpdateCompanionBuilder,
          (Permission, $$PermissionsTableReferences),
          Permission,
          PrefetchHooks Function({bool rolePermissionsRefs})
        > {
  $$PermissionsTableTableManager(_$AppDatabase db, $PermissionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$PermissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PermissionsCompanion(
                id: id,
                name: name,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PermissionsCompanion.insert(
                id: id,
                name: name,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PermissionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({rolePermissionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rolePermissionsRefs) db.rolePermissions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rolePermissionsRefs)
                    await $_getPrefetchedData<
                      Permission,
                      $PermissionsTable,
                      RolePermission
                    >(
                      currentTable: table,
                      referencedTable: $$PermissionsTableReferences
                          ._rolePermissionsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PermissionsTableReferences(
                                db,
                                table,
                                p0,
                              ).rolePermissionsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.permissionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PermissionsTable,
      Permission,
      $$PermissionsTableFilterComposer,
      $$PermissionsTableOrderingComposer,
      $$PermissionsTableAnnotationComposer,
      $$PermissionsTableCreateCompanionBuilder,
      $$PermissionsTableUpdateCompanionBuilder,
      (Permission, $$PermissionsTableReferences),
      Permission,
      PrefetchHooks Function({bool rolePermissionsRefs})
    >;
typedef $$RolePermissionsTableCreateCompanionBuilder =
    RolePermissionsCompanion Function({
      required String roleId,
      required String permissionId,
      Value<int> rowid,
    });
typedef $$RolePermissionsTableUpdateCompanionBuilder =
    RolePermissionsCompanion Function({
      Value<String> roleId,
      Value<String> permissionId,
      Value<int> rowid,
    });

final class $$RolePermissionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $RolePermissionsTable, RolePermission> {
  $$RolePermissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RolesTable _roleIdTable(_$AppDatabase db) => db.roles.createAlias(
    $_aliasNameGenerator(db.rolePermissions.roleId, db.roles.id),
  );

  $$RolesTableProcessedTableManager get roleId {
    final $_column = $_itemColumn<String>('role_id')!;

    final manager = $$RolesTableTableManager(
      $_db,
      $_db.roles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PermissionsTable _permissionIdTable(_$AppDatabase db) =>
      db.permissions.createAlias(
        $_aliasNameGenerator(
          db.rolePermissions.permissionId,
          db.permissions.id,
        ),
      );

  $$PermissionsTableProcessedTableManager get permissionId {
    final $_column = $_itemColumn<String>('permission_id')!;

    final manager = $$PermissionsTableTableManager(
      $_db,
      $_db.permissions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_permissionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RolePermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RolesTableFilterComposer get roleId {
    final $$RolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableFilterComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PermissionsTableFilterComposer get permissionId {
    final $$PermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.permissionId,
      referencedTable: $db.permissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PermissionsTableFilterComposer(
            $db: $db,
            $table: $db.permissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RolePermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RolesTableOrderingComposer get roleId {
    final $$RolesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableOrderingComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PermissionsTableOrderingComposer get permissionId {
    final $$PermissionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.permissionId,
      referencedTable: $db.permissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PermissionsTableOrderingComposer(
            $db: $db,
            $table: $db.permissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RolePermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RolesTableAnnotationComposer get roleId {
    final $$RolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableAnnotationComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PermissionsTableAnnotationComposer get permissionId {
    final $$PermissionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.permissionId,
      referencedTable: $db.permissions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PermissionsTableAnnotationComposer(
            $db: $db,
            $table: $db.permissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RolePermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolePermissionsTable,
          RolePermission,
          $$RolePermissionsTableFilterComposer,
          $$RolePermissionsTableOrderingComposer,
          $$RolePermissionsTableAnnotationComposer,
          $$RolePermissionsTableCreateCompanionBuilder,
          $$RolePermissionsTableUpdateCompanionBuilder,
          (RolePermission, $$RolePermissionsTableReferences),
          RolePermission,
          PrefetchHooks Function({bool roleId, bool permissionId})
        > {
  $$RolePermissionsTableTableManager(
    _$AppDatabase db,
    $RolePermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$RolePermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RolePermissionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$RolePermissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> roleId = const Value.absent(),
                Value<String> permissionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolePermissionsCompanion(
                roleId: roleId,
                permissionId: permissionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String roleId,
                required String permissionId,
                Value<int> rowid = const Value.absent(),
              }) => RolePermissionsCompanion.insert(
                roleId: roleId,
                permissionId: permissionId,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RolePermissionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({roleId = false, permissionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (roleId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.roleId,
                            referencedTable: $$RolePermissionsTableReferences
                                ._roleIdTable(db),
                            referencedColumn:
                                $$RolePermissionsTableReferences
                                    ._roleIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (permissionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.permissionId,
                            referencedTable: $$RolePermissionsTableReferences
                                ._permissionIdTable(db),
                            referencedColumn:
                                $$RolePermissionsTableReferences
                                    ._permissionIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RolePermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolePermissionsTable,
      RolePermission,
      $$RolePermissionsTableFilterComposer,
      $$RolePermissionsTableOrderingComposer,
      $$RolePermissionsTableAnnotationComposer,
      $$RolePermissionsTableCreateCompanionBuilder,
      $$RolePermissionsTableUpdateCompanionBuilder,
      (RolePermission, $$RolePermissionsTableReferences),
      RolePermission,
      PrefetchHooks Function({bool roleId, bool permissionId})
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String name,
      required String email,
      required String passwordHash,
      required String roleId,
      required String branchId,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> email,
      Value<String> passwordHash,
      Value<String> roleId,
      Value<String> branchId,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RolesTable _roleIdTable(_$AppDatabase db) =>
      db.roles.createAlias($_aliasNameGenerator(db.users.roleId, db.roles.id));

  $$RolesTableProcessedTableManager get roleId {
    final $_column = $_itemColumn<String>('role_id')!;

    final manager = $$RolesTableTableManager(
      $_db,
      $_db.roles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BranchesTable _branchIdTable(_$AppDatabase db) => db.branches
      .createAlias($_aliasNameGenerator(db.users.branchId, db.branches.id));

  $$BranchesTableProcessedTableManager get branchId {
    final $_column = $_itemColumn<String>('branch_id')!;

    final manager = $$BranchesTableTableManager(
      $_db,
      $_db.branches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RolesTableFilterComposer get roleId {
    final $$RolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableFilterComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableFilterComposer get branchId {
    final $$BranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableFilterComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RolesTableOrderingComposer get roleId {
    final $$RolesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableOrderingComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableOrderingComposer get branchId {
    final $$BranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableOrderingComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RolesTableAnnotationComposer get roleId {
    final $$RolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableAnnotationComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableAnnotationComposer get branchId {
    final $$BranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({bool roleId, bool branchId})
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                roleId: roleId,
                branchId: branchId,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String email,
                required String passwordHash,
                required String roleId,
                required String branchId,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                passwordHash: passwordHash,
                roleId: roleId,
                branchId: branchId,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$UsersTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({roleId = false, branchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (roleId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.roleId,
                            referencedTable: $$UsersTableReferences
                                ._roleIdTable(db),
                            referencedColumn:
                                $$UsersTableReferences._roleIdTable(db).id,
                          )
                          as T;
                }
                if (branchId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.branchId,
                            referencedTable: $$UsersTableReferences
                                ._branchIdTable(db),
                            referencedColumn:
                                $$UsersTableReferences._branchIdTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({bool roleId, bool branchId})
    >;
typedef $$UomsTableCreateCompanionBuilder =
    UomsCompanion Function({
      required String id,
      required String name,
      required String symbol,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UomsTableUpdateCompanionBuilder =
    UomsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> symbol,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$UomsTableReferences
    extends BaseReferences<_$AppDatabase, $UomsTable, Uom> {
  $$UomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.uoms.id, db.items.uomId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.uomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UomsTableFilterComposer extends Composer<_$AppDatabase, $UomsTable> {
  $$UomsTableFilterComposer({
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

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.uomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UomsTableOrderingComposer extends Composer<_$AppDatabase, $UomsTable> {
  $$UomsTableOrderingComposer({
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

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UomsTable> {
  $$UomsTableAnnotationComposer({
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

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.uomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UomsTable,
          Uom,
          $$UomsTableFilterComposer,
          $$UomsTableOrderingComposer,
          $$UomsTableAnnotationComposer,
          $$UomsTableCreateCompanionBuilder,
          $$UomsTableUpdateCompanionBuilder,
          (Uom, $$UomsTableReferences),
          Uom,
          PrefetchHooks Function({bool itemsRefs})
        > {
  $$UomsTableTableManager(_$AppDatabase db, $UomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UomsCompanion(
                id: id,
                name: name,
                symbol: symbol,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String symbol,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UomsCompanion.insert(
                id: id,
                name: name,
                symbol: symbol,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$UomsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedData<Uom, $UomsTable, Item>(
                      currentTable: table,
                      referencedTable: $$UomsTableReferences._itemsRefsTable(
                        db,
                      ),
                      managerFromTypedResult:
                          (p0) =>
                              $$UomsTableReferences(db, table, p0).itemsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.uomId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UomsTable,
      Uom,
      $$UomsTableFilterComposer,
      $$UomsTableOrderingComposer,
      $$UomsTableAnnotationComposer,
      $$UomsTableCreateCompanionBuilder,
      $$UomsTableUpdateCompanionBuilder,
      (Uom, $$UomsTableReferences),
      Uom,
      PrefetchHooks Function({bool itemsRefs})
    >;
typedef $$ItemCategoriesTableCreateCompanionBuilder =
    ItemCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ItemCategoriesTableUpdateCompanionBuilder =
    ItemCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ItemCategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $ItemCategoriesTable, ItemCategory> {
  $$ItemCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.itemCategories.id, db.items.categoryId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemCategoriesTable> {
  $$ItemCategoriesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemCategoriesTable> {
  $$ItemCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemCategoriesTable> {
  $$ItemCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemCategoriesTable,
          ItemCategory,
          $$ItemCategoriesTableFilterComposer,
          $$ItemCategoriesTableOrderingComposer,
          $$ItemCategoriesTableAnnotationComposer,
          $$ItemCategoriesTableCreateCompanionBuilder,
          $$ItemCategoriesTableUpdateCompanionBuilder,
          (ItemCategory, $$ItemCategoriesTableReferences),
          ItemCategory,
          PrefetchHooks Function({bool itemsRefs})
        > {
  $$ItemCategoriesTableTableManager(
    _$AppDatabase db,
    $ItemCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ItemCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ItemCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ItemCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemCategoriesCompanion(
                id: id,
                name: name,
                description: description,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemCategoriesCompanion.insert(
                id: id,
                name: name,
                description: description,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ItemCategoriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedData<
                      ItemCategory,
                      $ItemCategoriesTable,
                      Item
                    >(
                      currentTable: table,
                      referencedTable: $$ItemCategoriesTableReferences
                          ._itemsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ItemCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.categoryId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemCategoriesTable,
      ItemCategory,
      $$ItemCategoriesTableFilterComposer,
      $$ItemCategoriesTableOrderingComposer,
      $$ItemCategoriesTableAnnotationComposer,
      $$ItemCategoriesTableCreateCompanionBuilder,
      $$ItemCategoriesTableUpdateCompanionBuilder,
      (ItemCategory, $$ItemCategoriesTableReferences),
      ItemCategory,
      PrefetchHooks Function({bool itemsRefs})
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String name,
      Value<String?> barcode,
      required String categoryId,
      required String uomId,
      Value<double> costPrice,
      Value<double> sellPrice,
      Value<int> stockQty,
      Value<int> reorderLevel,
      Value<String?> iconCode,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> barcode,
      Value<String> categoryId,
      Value<String> uomId,
      Value<double> costPrice,
      Value<double> sellPrice,
      Value<int> stockQty,
      Value<int> reorderLevel,
      Value<String?> iconCode,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.itemCategories.createAlias(
        $_aliasNameGenerator(db.items.categoryId, db.itemCategories.id),
      );

  $$ItemCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$ItemCategoriesTableTableManager(
      $_db,
      $_db.itemCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UomsTable _uomIdTable(_$AppDatabase db) =>
      db.uoms.createAlias($_aliasNameGenerator(db.items.uomId, db.uoms.id));

  $$UomsTableProcessedTableManager get uomId {
    final $_column = $_itemColumn<String>('uom_id')!;

    final manager = $$UomsTableTableManager(
      $_db,
      $_db.uoms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_uomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PriceListItemsTable, List<PriceListItem>>
  _priceListItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceListItems,
    aliasName: $_aliasNameGenerator(db.items.id, db.priceListItems.itemId),
  );

  $$PriceListItemsTableProcessedTableManager get priceListItemsRefs {
    final manager = $$PriceListItemsTableTableManager(
      $_db,
      $_db.priceListItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceListItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StockLedgerEntriesTable, List<StockLedgerEntry>>
  _stockLedgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockLedgerEntries,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.stockLedgerEntries.itemId,
        ),
      );

  $$StockLedgerEntriesTableProcessedTableManager get stockLedgerEntriesRefs {
    final manager = $$StockLedgerEntriesTableTableManager(
      $_db,
      $_db.stockLedgerEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stockLedgerEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemCategoriesTableFilterComposer get categoryId {
    final $$ItemCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.itemCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.itemCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UomsTableFilterComposer get uomId {
    final $$UomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uomId,
      referencedTable: $db.uoms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UomsTableFilterComposer(
            $db: $db,
            $table: $db.uoms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> priceListItemsRefs(
    Expression<bool> Function($$PriceListItemsTableFilterComposer f) f,
  ) {
    final $$PriceListItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceListItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListItemsTableFilterComposer(
            $db: $db,
            $table: $db.priceListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockLedgerEntriesRefs(
    Expression<bool> Function($$StockLedgerEntriesTableFilterComposer f) f,
  ) {
    final $$StockLedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockLedgerEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockLedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.stockLedgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemCategoriesTableOrderingComposer get categoryId {
    final $$ItemCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.itemCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.itemCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UomsTableOrderingComposer get uomId {
    final $$UomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uomId,
      referencedTable: $db.uoms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UomsTableOrderingComposer(
            $db: $db,
            $table: $db.uoms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemCategoriesTableAnnotationComposer get categoryId {
    final $$ItemCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.itemCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.itemCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UomsTableAnnotationComposer get uomId {
    final $$UomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uomId,
      referencedTable: $db.uoms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UomsTableAnnotationComposer(
            $db: $db,
            $table: $db.uoms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> priceListItemsRefs<T extends Object>(
    Expression<T> Function($$PriceListItemsTableAnnotationComposer a) f,
  ) {
    final $$PriceListItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceListItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.priceListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stockLedgerEntriesRefs<T extends Object>(
    Expression<T> Function($$StockLedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$StockLedgerEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stockLedgerEntries,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StockLedgerEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.stockLedgerEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool categoryId,
            bool uomId,
            bool priceListItemsRefs,
            bool stockLedgerEntriesRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> uomId = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<int> stockQty = const Value.absent(),
                Value<int> reorderLevel = const Value.absent(),
                Value<String?> iconCode = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                name: name,
                barcode: barcode,
                categoryId: categoryId,
                uomId: uomId,
                costPrice: costPrice,
                sellPrice: sellPrice,
                stockQty: stockQty,
                reorderLevel: reorderLevel,
                iconCode: iconCode,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> barcode = const Value.absent(),
                required String categoryId,
                required String uomId,
                Value<double> costPrice = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<int> stockQty = const Value.absent(),
                Value<int> reorderLevel = const Value.absent(),
                Value<String?> iconCode = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                name: name,
                barcode: barcode,
                categoryId: categoryId,
                uomId: uomId,
                costPrice: costPrice,
                sellPrice: sellPrice,
                stockQty: stockQty,
                reorderLevel: reorderLevel,
                iconCode: iconCode,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ItemsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            categoryId = false,
            uomId = false,
            priceListItemsRefs = false,
            stockLedgerEntriesRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (priceListItemsRefs) db.priceListItems,
                if (stockLedgerEntriesRefs) db.stockLedgerEntries,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (categoryId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$ItemsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn:
                                $$ItemsTableReferences._categoryIdTable(db).id,
                          )
                          as T;
                }
                if (uomId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.uomId,
                            referencedTable: $$ItemsTableReferences._uomIdTable(
                              db,
                            ),
                            referencedColumn:
                                $$ItemsTableReferences._uomIdTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (priceListItemsRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, PriceListItem>(
                      currentTable: table,
                      referencedTable: $$ItemsTableReferences
                          ._priceListItemsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceListItemsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                  if (stockLedgerEntriesRefs)
                    await $_getPrefetchedData<
                      Item,
                      $ItemsTable,
                      StockLedgerEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ItemsTableReferences
                          ._stockLedgerEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).stockLedgerEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool categoryId,
        bool uomId,
        bool priceListItemsRefs,
        bool stockLedgerEntriesRefs,
      })
    >;
typedef $$PriceListsTableCreateCompanionBuilder =
    PriceListsCompanion Function({
      required String id,
      required String name,
      Value<String> currency,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PriceListsTableUpdateCompanionBuilder =
    PriceListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currency,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PriceListsTableReferences
    extends BaseReferences<_$AppDatabase, $PriceListsTable, PriceList> {
  $$PriceListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PriceListItemsTable, List<PriceListItem>>
  _priceListItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceListItems,
    aliasName: $_aliasNameGenerator(
      db.priceLists.id,
      db.priceListItems.priceListId,
    ),
  );

  $$PriceListItemsTableProcessedTableManager get priceListItemsRefs {
    final manager = $$PriceListItemsTableTableManager(
      $_db,
      $_db.priceListItems,
    ).filter((f) => f.priceListId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceListItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PriceListsTableFilterComposer
    extends Composer<_$AppDatabase, $PriceListsTable> {
  $$PriceListsTableFilterComposer({
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

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> priceListItemsRefs(
    Expression<bool> Function($$PriceListItemsTableFilterComposer f) f,
  ) {
    final $$PriceListItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceListItems,
      getReferencedColumn: (t) => t.priceListId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListItemsTableFilterComposer(
            $db: $db,
            $table: $db.priceListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PriceListsTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceListsTable> {
  $$PriceListsTableOrderingComposer({
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

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceListsTable> {
  $$PriceListsTableAnnotationComposer({
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

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> priceListItemsRefs<T extends Object>(
    Expression<T> Function($$PriceListItemsTableAnnotationComposer a) f,
  ) {
    final $$PriceListItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceListItems,
      getReferencedColumn: (t) => t.priceListId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.priceListItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PriceListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceListsTable,
          PriceList,
          $$PriceListsTableFilterComposer,
          $$PriceListsTableOrderingComposer,
          $$PriceListsTableAnnotationComposer,
          $$PriceListsTableCreateCompanionBuilder,
          $$PriceListsTableUpdateCompanionBuilder,
          (PriceList, $$PriceListsTableReferences),
          PriceList,
          PrefetchHooks Function({bool priceListItemsRefs})
        > {
  $$PriceListsTableTableManager(_$AppDatabase db, $PriceListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PriceListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PriceListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PriceListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceListsCompanion(
                id: id,
                name: name,
                currency: currency,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> currency = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceListsCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PriceListsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({priceListItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (priceListItemsRefs) db.priceListItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (priceListItemsRefs)
                    await $_getPrefetchedData<
                      PriceList,
                      $PriceListsTable,
                      PriceListItem
                    >(
                      currentTable: table,
                      referencedTable: $$PriceListsTableReferences
                          ._priceListItemsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PriceListsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceListItemsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.priceListId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PriceListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceListsTable,
      PriceList,
      $$PriceListsTableFilterComposer,
      $$PriceListsTableOrderingComposer,
      $$PriceListsTableAnnotationComposer,
      $$PriceListsTableCreateCompanionBuilder,
      $$PriceListsTableUpdateCompanionBuilder,
      (PriceList, $$PriceListsTableReferences),
      PriceList,
      PrefetchHooks Function({bool priceListItemsRefs})
    >;
typedef $$PriceListItemsTableCreateCompanionBuilder =
    PriceListItemsCompanion Function({
      required String priceListId,
      required String itemId,
      required double price,
      Value<int> rowid,
    });
typedef $$PriceListItemsTableUpdateCompanionBuilder =
    PriceListItemsCompanion Function({
      Value<String> priceListId,
      Value<String> itemId,
      Value<double> price,
      Value<int> rowid,
    });

final class $$PriceListItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PriceListItemsTable, PriceListItem> {
  $$PriceListItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PriceListsTable _priceListIdTable(_$AppDatabase db) =>
      db.priceLists.createAlias(
        $_aliasNameGenerator(db.priceListItems.priceListId, db.priceLists.id),
      );

  $$PriceListsTableProcessedTableManager get priceListId {
    final $_column = $_itemColumn<String>('price_list_id')!;

    final manager = $$PriceListsTableTableManager(
      $_db,
      $_db.priceLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_priceListIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.priceListItems.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PriceListItemsTable> {
  $$PriceListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  $$PriceListsTableFilterComposer get priceListId {
    final $$PriceListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.priceListId,
      referencedTable: $db.priceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListsTableFilterComposer(
            $db: $db,
            $table: $db.priceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceListItemsTable> {
  $$PriceListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  $$PriceListsTableOrderingComposer get priceListId {
    final $$PriceListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.priceListId,
      referencedTable: $db.priceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListsTableOrderingComposer(
            $db: $db,
            $table: $db.priceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceListItemsTable> {
  $$PriceListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  $$PriceListsTableAnnotationComposer get priceListId {
    final $$PriceListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.priceListId,
      referencedTable: $db.priceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceListsTableAnnotationComposer(
            $db: $db,
            $table: $db.priceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceListItemsTable,
          PriceListItem,
          $$PriceListItemsTableFilterComposer,
          $$PriceListItemsTableOrderingComposer,
          $$PriceListItemsTableAnnotationComposer,
          $$PriceListItemsTableCreateCompanionBuilder,
          $$PriceListItemsTableUpdateCompanionBuilder,
          (PriceListItem, $$PriceListItemsTableReferences),
          PriceListItem,
          PrefetchHooks Function({bool priceListId, bool itemId})
        > {
  $$PriceListItemsTableTableManager(
    _$AppDatabase db,
    $PriceListItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PriceListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$PriceListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PriceListItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> priceListId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceListItemsCompanion(
                priceListId: priceListId,
                itemId: itemId,
                price: price,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String priceListId,
                required String itemId,
                required double price,
                Value<int> rowid = const Value.absent(),
              }) => PriceListItemsCompanion.insert(
                priceListId: priceListId,
                itemId: itemId,
                price: price,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PriceListItemsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({priceListId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (priceListId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.priceListId,
                            referencedTable: $$PriceListItemsTableReferences
                                ._priceListIdTable(db),
                            referencedColumn:
                                $$PriceListItemsTableReferences
                                    ._priceListIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (itemId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.itemId,
                            referencedTable: $$PriceListItemsTableReferences
                                ._itemIdTable(db),
                            referencedColumn:
                                $$PriceListItemsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PriceListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceListItemsTable,
      PriceListItem,
      $$PriceListItemsTableFilterComposer,
      $$PriceListItemsTableOrderingComposer,
      $$PriceListItemsTableAnnotationComposer,
      $$PriceListItemsTableCreateCompanionBuilder,
      $$PriceListItemsTableUpdateCompanionBuilder,
      (PriceListItem, $$PriceListItemsTableReferences),
      PriceListItem,
      PrefetchHooks Function({bool priceListId, bool itemId})
    >;
typedef $$WarehousesTableCreateCompanionBuilder =
    WarehousesCompanion Function({
      required String id,
      required String name,
      required String branchId,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$WarehousesTableUpdateCompanionBuilder =
    WarehousesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> branchId,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$WarehousesTableReferences
    extends BaseReferences<_$AppDatabase, $WarehousesTable, Warehouse> {
  $$WarehousesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BranchesTable _branchIdTable(_$AppDatabase db) =>
      db.branches.createAlias(
        $_aliasNameGenerator(db.warehouses.branchId, db.branches.id),
      );

  $$BranchesTableProcessedTableManager get branchId {
    final $_column = $_itemColumn<String>('branch_id')!;

    final manager = $$BranchesTableTableManager(
      $_db,
      $_db.branches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StockLedgerEntriesTable, List<StockLedgerEntry>>
  _stockLedgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockLedgerEntries,
        aliasName: $_aliasNameGenerator(
          db.warehouses.id,
          db.stockLedgerEntries.warehouseId,
        ),
      );

  $$StockLedgerEntriesTableProcessedTableManager get stockLedgerEntriesRefs {
    final manager = $$StockLedgerEntriesTableTableManager(
      $_db,
      $_db.stockLedgerEntries,
    ).filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stockLedgerEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WarehousesTableFilterComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableFilterComposer({
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

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BranchesTableFilterComposer get branchId {
    final $$BranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableFilterComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stockLedgerEntriesRefs(
    Expression<bool> Function($$StockLedgerEntriesTableFilterComposer f) f,
  ) {
    final $$StockLedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockLedgerEntries,
      getReferencedColumn: (t) => t.warehouseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockLedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.stockLedgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WarehousesTableOrderingComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableOrderingComposer({
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

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BranchesTableOrderingComposer get branchId {
    final $$BranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableOrderingComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WarehousesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableAnnotationComposer({
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

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BranchesTableAnnotationComposer get branchId {
    final $$BranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stockLedgerEntriesRefs<T extends Object>(
    Expression<T> Function($$StockLedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$StockLedgerEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stockLedgerEntries,
          getReferencedColumn: (t) => t.warehouseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StockLedgerEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.stockLedgerEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WarehousesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WarehousesTable,
          Warehouse,
          $$WarehousesTableFilterComposer,
          $$WarehousesTableOrderingComposer,
          $$WarehousesTableAnnotationComposer,
          $$WarehousesTableCreateCompanionBuilder,
          $$WarehousesTableUpdateCompanionBuilder,
          (Warehouse, $$WarehousesTableReferences),
          Warehouse,
          PrefetchHooks Function({bool branchId, bool stockLedgerEntriesRefs})
        > {
  $$WarehousesTableTableManager(_$AppDatabase db, $WarehousesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$WarehousesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$WarehousesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$WarehousesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion(
                id: id,
                name: name,
                branchId: branchId,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String branchId,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion.insert(
                id: id,
                name: name,
                branchId: branchId,
                active: active,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$WarehousesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            branchId = false,
            stockLedgerEntriesRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockLedgerEntriesRefs) db.stockLedgerEntries,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (branchId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.branchId,
                            referencedTable: $$WarehousesTableReferences
                                ._branchIdTable(db),
                            referencedColumn:
                                $$WarehousesTableReferences
                                    ._branchIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockLedgerEntriesRefs)
                    await $_getPrefetchedData<
                      Warehouse,
                      $WarehousesTable,
                      StockLedgerEntry
                    >(
                      currentTable: table,
                      referencedTable: $$WarehousesTableReferences
                          ._stockLedgerEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$WarehousesTableReferences(
                                db,
                                table,
                                p0,
                              ).stockLedgerEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.warehouseId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WarehousesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WarehousesTable,
      Warehouse,
      $$WarehousesTableFilterComposer,
      $$WarehousesTableOrderingComposer,
      $$WarehousesTableAnnotationComposer,
      $$WarehousesTableCreateCompanionBuilder,
      $$WarehousesTableUpdateCompanionBuilder,
      (Warehouse, $$WarehousesTableReferences),
      Warehouse,
      PrefetchHooks Function({bool branchId, bool stockLedgerEntriesRefs})
    >;
typedef $$StockLedgerEntriesTableCreateCompanionBuilder =
    StockLedgerEntriesCompanion Function({
      required String id,
      required String itemId,
      required String warehouseId,
      required double qtyChange,
      required double balanceAfter,
      required String voucherType,
      required String voucherId,
      Value<String?> batchNo,
      Value<String?> reversalOf,
      Value<String?> reason,
      required DateTime postingDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$StockLedgerEntriesTableUpdateCompanionBuilder =
    StockLedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> warehouseId,
      Value<double> qtyChange,
      Value<double> balanceAfter,
      Value<String> voucherType,
      Value<String> voucherId,
      Value<String?> batchNo,
      Value<String?> reversalOf,
      Value<String?> reason,
      Value<DateTime> postingDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$StockLedgerEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StockLedgerEntriesTable,
          StockLedgerEntry
        > {
  $$StockLedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.stockLedgerEntries.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WarehousesTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehouses.createAlias(
        $_aliasNameGenerator(
          db.stockLedgerEntries.warehouseId,
          db.warehouses.id,
        ),
      );

  $$WarehousesTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableManager(
      $_db,
      $_db.warehouses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockLedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StockLedgerEntriesTable> {
  $$StockLedgerEntriesTableFilterComposer({
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

  ColumnFilters<double> get qtyChange => $composableBuilder(
    column: $table.qtyChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherId => $composableBuilder(
    column: $table.voucherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchNo => $composableBuilder(
    column: $table.batchNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversalOf => $composableBuilder(
    column: $table.reversalOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postingDate => $composableBuilder(
    column: $table.postingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WarehousesTableFilterComposer get warehouseId {
    final $$WarehousesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehouses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableFilterComposer(
            $db: $db,
            $table: $db.warehouses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockLedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLedgerEntriesTable> {
  $$StockLedgerEntriesTableOrderingComposer({
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

  ColumnOrderings<double> get qtyChange => $composableBuilder(
    column: $table.qtyChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherId => $composableBuilder(
    column: $table.voucherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchNo => $composableBuilder(
    column: $table.batchNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversalOf => $composableBuilder(
    column: $table.reversalOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postingDate => $composableBuilder(
    column: $table.postingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WarehousesTableOrderingComposer get warehouseId {
    final $$WarehousesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehouses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableOrderingComposer(
            $db: $db,
            $table: $db.warehouses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockLedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLedgerEntriesTable> {
  $$StockLedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get qtyChange =>
      $composableBuilder(column: $table.qtyChange, builder: (column) => column);

  GeneratedColumn<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voucherId =>
      $composableBuilder(column: $table.voucherId, builder: (column) => column);

  GeneratedColumn<String> get batchNo =>
      $composableBuilder(column: $table.batchNo, builder: (column) => column);

  GeneratedColumn<String> get reversalOf => $composableBuilder(
    column: $table.reversalOf,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get postingDate => $composableBuilder(
    column: $table.postingDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WarehousesTableAnnotationComposer get warehouseId {
    final $$WarehousesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehouses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableAnnotationComposer(
            $db: $db,
            $table: $db.warehouses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockLedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockLedgerEntriesTable,
          StockLedgerEntry,
          $$StockLedgerEntriesTableFilterComposer,
          $$StockLedgerEntriesTableOrderingComposer,
          $$StockLedgerEntriesTableAnnotationComposer,
          $$StockLedgerEntriesTableCreateCompanionBuilder,
          $$StockLedgerEntriesTableUpdateCompanionBuilder,
          (StockLedgerEntry, $$StockLedgerEntriesTableReferences),
          StockLedgerEntry,
          PrefetchHooks Function({bool itemId, bool warehouseId})
        > {
  $$StockLedgerEntriesTableTableManager(
    _$AppDatabase db,
    $StockLedgerEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StockLedgerEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$StockLedgerEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$StockLedgerEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> warehouseId = const Value.absent(),
                Value<double> qtyChange = const Value.absent(),
                Value<double> balanceAfter = const Value.absent(),
                Value<String> voucherType = const Value.absent(),
                Value<String> voucherId = const Value.absent(),
                Value<String?> batchNo = const Value.absent(),
                Value<String?> reversalOf = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> postingDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLedgerEntriesCompanion(
                id: id,
                itemId: itemId,
                warehouseId: warehouseId,
                qtyChange: qtyChange,
                balanceAfter: balanceAfter,
                voucherType: voucherType,
                voucherId: voucherId,
                batchNo: batchNo,
                reversalOf: reversalOf,
                reason: reason,
                postingDate: postingDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String warehouseId,
                required double qtyChange,
                required double balanceAfter,
                required String voucherType,
                required String voucherId,
                Value<String?> batchNo = const Value.absent(),
                Value<String?> reversalOf = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                required DateTime postingDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLedgerEntriesCompanion.insert(
                id: id,
                itemId: itemId,
                warehouseId: warehouseId,
                qtyChange: qtyChange,
                balanceAfter: balanceAfter,
                voucherType: voucherType,
                voucherId: voucherId,
                batchNo: batchNo,
                reversalOf: reversalOf,
                reason: reason,
                postingDate: postingDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$StockLedgerEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({itemId = false, warehouseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (itemId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.itemId,
                            referencedTable: $$StockLedgerEntriesTableReferences
                                ._itemIdTable(db),
                            referencedColumn:
                                $$StockLedgerEntriesTableReferences
                                    ._itemIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (warehouseId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.warehouseId,
                            referencedTable: $$StockLedgerEntriesTableReferences
                                ._warehouseIdTable(db),
                            referencedColumn:
                                $$StockLedgerEntriesTableReferences
                                    ._warehouseIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockLedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockLedgerEntriesTable,
      StockLedgerEntry,
      $$StockLedgerEntriesTableFilterComposer,
      $$StockLedgerEntriesTableOrderingComposer,
      $$StockLedgerEntriesTableAnnotationComposer,
      $$StockLedgerEntriesTableCreateCompanionBuilder,
      $$StockLedgerEntriesTableUpdateCompanionBuilder,
      (StockLedgerEntry, $$StockLedgerEntriesTableReferences),
      StockLedgerEntry,
      PrefetchHooks Function({bool itemId, bool warehouseId})
    >;
typedef $$LicensesTableCreateCompanionBuilder =
    LicensesCompanion Function({
      required String id,
      required String code,
      required String customerName,
      required String fingerprint,
      required String planCode,
      required DateTime issuedAt,
      required DateTime expiresAt,
      required DateTime activatedAt,
      Value<int> rowid,
    });
typedef $$LicensesTableUpdateCompanionBuilder =
    LicensesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> customerName,
      Value<String> fingerprint,
      Value<String> planCode,
      Value<DateTime> issuedAt,
      Value<DateTime> expiresAt,
      Value<DateTime> activatedAt,
      Value<int> rowid,
    });

class $$LicensesTableFilterComposer
    extends Composer<_$AppDatabase, $LicensesTable> {
  $$LicensesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planCode => $composableBuilder(
    column: $table.planCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LicensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LicensesTable> {
  $$LicensesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planCode => $composableBuilder(
    column: $table.planCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LicensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LicensesTable> {
  $$LicensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planCode =>
      $composableBuilder(column: $table.planCode, builder: (column) => column);

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => column,
  );
}

class $$LicensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LicensesTable,
          LicenseRecord,
          $$LicensesTableFilterComposer,
          $$LicensesTableOrderingComposer,
          $$LicensesTableAnnotationComposer,
          $$LicensesTableCreateCompanionBuilder,
          $$LicensesTableUpdateCompanionBuilder,
          (
            LicenseRecord,
            BaseReferences<_$AppDatabase, $LicensesTable, LicenseRecord>,
          ),
          LicenseRecord,
          PrefetchHooks Function()
        > {
  $$LicensesTableTableManager(_$AppDatabase db, $LicensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LicensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LicensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LicensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String> planCode = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> activatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LicensesCompanion(
                id: id,
                code: code,
                customerName: customerName,
                fingerprint: fingerprint,
                planCode: planCode,
                issuedAt: issuedAt,
                expiresAt: expiresAt,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String customerName,
                required String fingerprint,
                required String planCode,
                required DateTime issuedAt,
                required DateTime expiresAt,
                required DateTime activatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LicensesCompanion.insert(
                id: id,
                code: code,
                customerName: customerName,
                fingerprint: fingerprint,
                planCode: planCode,
                issuedAt: issuedAt,
                expiresAt: expiresAt,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LicensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LicensesTable,
      LicenseRecord,
      $$LicensesTableFilterComposer,
      $$LicensesTableOrderingComposer,
      $$LicensesTableAnnotationComposer,
      $$LicensesTableCreateCompanionBuilder,
      $$LicensesTableUpdateCompanionBuilder,
      (
        LicenseRecord,
        BaseReferences<_$AppDatabase, $LicensesTable, LicenseRecord>,
      ),
      LicenseRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BranchesTableTableManager get branches =>
      $$BranchesTableTableManager(_db, _db.branches);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db, _db.roles);
  $$PermissionsTableTableManager get permissions =>
      $$PermissionsTableTableManager(_db, _db.permissions);
  $$RolePermissionsTableTableManager get rolePermissions =>
      $$RolePermissionsTableTableManager(_db, _db.rolePermissions);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$UomsTableTableManager get uoms => $$UomsTableTableManager(_db, _db.uoms);
  $$ItemCategoriesTableTableManager get itemCategories =>
      $$ItemCategoriesTableTableManager(_db, _db.itemCategories);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$PriceListsTableTableManager get priceLists =>
      $$PriceListsTableTableManager(_db, _db.priceLists);
  $$PriceListItemsTableTableManager get priceListItems =>
      $$PriceListItemsTableTableManager(_db, _db.priceListItems);
  $$WarehousesTableTableManager get warehouses =>
      $$WarehousesTableTableManager(_db, _db.warehouses);
  $$StockLedgerEntriesTableTableManager get stockLedgerEntries =>
      $$StockLedgerEntriesTableTableManager(_db, _db.stockLedgerEntries);
  $$LicensesTableTableManager get licenses =>
      $$LicensesTableTableManager(_db, _db.licenses);
}
