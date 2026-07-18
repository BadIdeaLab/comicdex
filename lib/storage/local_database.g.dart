// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $AppOptionsTable extends AppOptions
    with TableInfo<$AppOptionsTable, AppOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppOptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Options';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  AppOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppOption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppOptionsTable createAlias(String alias) {
    return $AppOptionsTable(attachedDatabase, alias);
  }
}

class AppOption extends DataClass implements Insertable<AppOption> {
  final int id;
  final String name;
  final String value;
  const AppOption({required this.id, required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppOptionsCompanion toCompanion(bool nullToAbsent) {
    return AppOptionsCompanion(
      id: Value(id),
      name: Value(name),
      value: Value(value),
    );
  }

  factory AppOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppOption(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  AppOption copyWith({int? id, String? name, String? value}) => AppOption(
    id: id ?? this.id,
    name: name ?? this.name,
    value: value ?? this.value,
  );
  AppOption copyWithCompanion(AppOptionsCompanion data) {
    return AppOption(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppOption(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppOption &&
          other.id == this.id &&
          other.name == this.name &&
          other.value == this.value);
}

class AppOptionsCompanion extends UpdateCompanion<AppOption> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> value;
  const AppOptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.value = const Value.absent(),
  });
  AppOptionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String value,
  }) : name = Value(name),
       value = Value(value);
  static Insertable<AppOption> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
    });
  }

  AppOptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? value,
  }) {
    return AppOptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppOptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $ComicsTable extends Comics with TableInfo<$ComicsTable, Comic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _midMeta = const VerificationMeta('mid');
  @override
  late final GeneratedColumn<String> mid = GeneratedColumn<String>(
    'mid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pagesMeta = const VerificationMeta('pages');
  @override
  late final GeneratedColumn<int> pages = GeneratedColumn<int>(
    'pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mid, title, images, pages];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Comic';
  @override
  VerificationContext validateIntegrity(
    Insertable<Comic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mid')) {
      context.handle(
        _midMeta,
        mid.isAcceptableOrUnknown(data['mid']!, _midMeta),
      );
    } else if (isInserting) {
      context.missing(_midMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    } else if (isInserting) {
      context.missing(_imagesMeta);
    }
    if (data.containsKey('pages')) {
      context.handle(
        _pagesMeta,
        pages.isAcceptableOrUnknown(data['pages']!, _pagesMeta),
      );
    } else if (isInserting) {
      context.missing(_pagesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Comic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      )!,
      pages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages'],
      )!,
    );
  }

  @override
  $ComicsTable createAlias(String alias) {
    return $ComicsTable(attachedDatabase, alias);
  }
}

class Comic extends DataClass implements Insertable<Comic> {
  final String id;
  final String mid;
  final String title;
  final String images;
  final int pages;
  const Comic({
    required this.id,
    required this.mid,
    required this.title,
    required this.images,
    required this.pages,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mid'] = Variable<String>(mid);
    map['title'] = Variable<String>(title);
    map['images'] = Variable<String>(images);
    map['pages'] = Variable<int>(pages);
    return map;
  }

  ComicsCompanion toCompanion(bool nullToAbsent) {
    return ComicsCompanion(
      id: Value(id),
      mid: Value(mid),
      title: Value(title),
      images: Value(images),
      pages: Value(pages),
    );
  }

  factory Comic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comic(
      id: serializer.fromJson<String>(json['id']),
      mid: serializer.fromJson<String>(json['mid']),
      title: serializer.fromJson<String>(json['title']),
      images: serializer.fromJson<String>(json['images']),
      pages: serializer.fromJson<int>(json['pages']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mid': serializer.toJson<String>(mid),
      'title': serializer.toJson<String>(title),
      'images': serializer.toJson<String>(images),
      'pages': serializer.toJson<int>(pages),
    };
  }

  Comic copyWith({
    String? id,
    String? mid,
    String? title,
    String? images,
    int? pages,
  }) => Comic(
    id: id ?? this.id,
    mid: mid ?? this.mid,
    title: title ?? this.title,
    images: images ?? this.images,
    pages: pages ?? this.pages,
  );
  Comic copyWithCompanion(ComicsCompanion data) {
    return Comic(
      id: data.id.present ? data.id.value : this.id,
      mid: data.mid.present ? data.mid.value : this.mid,
      title: data.title.present ? data.title.value : this.title,
      images: data.images.present ? data.images.value : this.images,
      pages: data.pages.present ? data.pages.value : this.pages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Comic(')
          ..write('id: $id, ')
          ..write('mid: $mid, ')
          ..write('title: $title, ')
          ..write('images: $images, ')
          ..write('pages: $pages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mid, title, images, pages);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comic &&
          other.id == this.id &&
          other.mid == this.mid &&
          other.title == this.title &&
          other.images == this.images &&
          other.pages == this.pages);
}

class ComicsCompanion extends UpdateCompanion<Comic> {
  final Value<String> id;
  final Value<String> mid;
  final Value<String> title;
  final Value<String> images;
  final Value<int> pages;
  final Value<int> rowid;
  const ComicsCompanion({
    this.id = const Value.absent(),
    this.mid = const Value.absent(),
    this.title = const Value.absent(),
    this.images = const Value.absent(),
    this.pages = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComicsCompanion.insert({
    required String id,
    required String mid,
    required String title,
    required String images,
    required int pages,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mid = Value(mid),
       title = Value(title),
       images = Value(images),
       pages = Value(pages);
  static Insertable<Comic> custom({
    Expression<String>? id,
    Expression<String>? mid,
    Expression<String>? title,
    Expression<String>? images,
    Expression<int>? pages,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mid != null) 'mid': mid,
      if (title != null) 'title': title,
      if (images != null) 'images': images,
      if (pages != null) 'pages': pages,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComicsCompanion copyWith({
    Value<String>? id,
    Value<String>? mid,
    Value<String>? title,
    Value<String>? images,
    Value<int>? pages,
    Value<int>? rowid,
  }) {
    return ComicsCompanion(
      id: id ?? this.id,
      mid: mid ?? this.mid,
      title: title ?? this.title,
      images: images ?? this.images,
      pages: pages ?? this.pages,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mid.present) {
      map['mid'] = Variable<String>(mid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (pages.present) {
      map['pages'] = Variable<int>(pages.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComicsCompanion(')
          ..write('id: $id, ')
          ..write('mid: $mid, ')
          ..write('title: $title, ')
          ..write('images: $images, ')
          ..write('pages: $pages, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comicidMeta = const VerificationMeta(
    'comicid',
  );
  @override
  late final GeneratedColumn<String> comicid = GeneratedColumn<String>(
    'comicid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateCreatedMeta = const VerificationMeta(
    'dateCreated',
  );
  @override
  late final GeneratedColumn<String> dateCreated = GeneratedColumn<String>(
    'dateCreated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favoriteRankMeta = const VerificationMeta(
    'favoriteRank',
  );
  @override
  late final GeneratedColumn<int> favoriteRank = GeneratedColumn<int>(
    'favorite_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    comicid,
    dateCreated,
    favoriteRank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Collection';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('comicid')) {
      context.handle(
        _comicidMeta,
        comicid.isAcceptableOrUnknown(data['comicid']!, _comicidMeta),
      );
    } else if (isInserting) {
      context.missing(_comicidMeta);
    }
    if (data.containsKey('dateCreated')) {
      context.handle(
        _dateCreatedMeta,
        dateCreated.isAcceptableOrUnknown(
          data['dateCreated']!,
          _dateCreatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateCreatedMeta);
    }
    if (data.containsKey('favorite_rank')) {
      context.handle(
        _favoriteRankMeta,
        favoriteRank.isAcceptableOrUnknown(
          data['favorite_rank']!,
          _favoriteRankMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name, comicid};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      comicid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comicid'],
      )!,
      dateCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dateCreated'],
      )!,
      favoriteRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favorite_rank'],
      ),
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String name;
  final String comicid;
  final String dateCreated;

  /// Position in the remote favorites list (0 = most recently favorited).
  /// Only populated for the `favorite` collection; null for all others.
  final int? favoriteRank;
  const Collection({
    required this.name,
    required this.comicid,
    required this.dateCreated,
    this.favoriteRank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['comicid'] = Variable<String>(comicid);
    map['dateCreated'] = Variable<String>(dateCreated);
    if (!nullToAbsent || favoriteRank != null) {
      map['favorite_rank'] = Variable<int>(favoriteRank);
    }
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      name: Value(name),
      comicid: Value(comicid),
      dateCreated: Value(dateCreated),
      favoriteRank: favoriteRank == null && nullToAbsent
          ? const Value.absent()
          : Value(favoriteRank),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      name: serializer.fromJson<String>(json['name']),
      comicid: serializer.fromJson<String>(json['comicid']),
      dateCreated: serializer.fromJson<String>(json['dateCreated']),
      favoriteRank: serializer.fromJson<int?>(json['favoriteRank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'comicid': serializer.toJson<String>(comicid),
      'dateCreated': serializer.toJson<String>(dateCreated),
      'favoriteRank': serializer.toJson<int?>(favoriteRank),
    };
  }

  Collection copyWith({
    String? name,
    String? comicid,
    String? dateCreated,
    Value<int?> favoriteRank = const Value.absent(),
  }) => Collection(
    name: name ?? this.name,
    comicid: comicid ?? this.comicid,
    dateCreated: dateCreated ?? this.dateCreated,
    favoriteRank: favoriteRank.present ? favoriteRank.value : this.favoriteRank,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      name: data.name.present ? data.name.value : this.name,
      comicid: data.comicid.present ? data.comicid.value : this.comicid,
      dateCreated: data.dateCreated.present
          ? data.dateCreated.value
          : this.dateCreated,
      favoriteRank: data.favoriteRank.present
          ? data.favoriteRank.value
          : this.favoriteRank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('name: $name, ')
          ..write('comicid: $comicid, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('favoriteRank: $favoriteRank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, comicid, dateCreated, favoriteRank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.name == this.name &&
          other.comicid == this.comicid &&
          other.dateCreated == this.dateCreated &&
          other.favoriteRank == this.favoriteRank);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> name;
  final Value<String> comicid;
  final Value<String> dateCreated;
  final Value<int?> favoriteRank;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.name = const Value.absent(),
    this.comicid = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.favoriteRank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String name,
    required String comicid,
    required String dateCreated,
    this.favoriteRank = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       comicid = Value(comicid),
       dateCreated = Value(dateCreated);
  static Insertable<Collection> custom({
    Expression<String>? name,
    Expression<String>? comicid,
    Expression<String>? dateCreated,
    Expression<int>? favoriteRank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (comicid != null) 'comicid': comicid,
      if (dateCreated != null) 'dateCreated': dateCreated,
      if (favoriteRank != null) 'favorite_rank': favoriteRank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? name,
    Value<String>? comicid,
    Value<String>? dateCreated,
    Value<int?>? favoriteRank,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      name: name ?? this.name,
      comicid: comicid ?? this.comicid,
      dateCreated: dateCreated ?? this.dateCreated,
      favoriteRank: favoriteRank ?? this.favoriteRank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (comicid.present) {
      map['comicid'] = Variable<String>(comicid.value);
    }
    if (dateCreated.present) {
      map['dateCreated'] = Variable<String>(dateCreated.value);
    }
    if (favoriteRank.present) {
      map['favorite_rank'] = Variable<int>(favoriteRank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('name: $name, ')
          ..write('comicid: $comicid, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('favoriteRank: $favoriteRank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoriesTable extends SearchHistories
    with TableInfo<$SearchHistoriesTable, SearchHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT CURRENT_TIMESTAMP',
    defaultValue: const CustomExpression('CURRENT_TIMESTAMP'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, query, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SearchHistory';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
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
  SearchHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SearchHistoriesTable createAlias(String alias) {
    return $SearchHistoriesTable(attachedDatabase, alias);
  }
}

class SearchHistory extends DataClass implements Insertable<SearchHistory> {
  final int id;
  final String query;
  final String createdAt;
  const SearchHistory({
    required this.id,
    required this.query,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query'] = Variable<String>(query);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SearchHistoriesCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoriesCompanion(
      id: Value(id),
      query: Value(query),
      createdAt: Value(createdAt),
    );
  }

  factory SearchHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistory(
      id: serializer.fromJson<int>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'query': serializer.toJson<String>(query),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SearchHistory copyWith({int? id, String? query, String? createdAt}) =>
      SearchHistory(
        id: id ?? this.id,
        query: query ?? this.query,
        createdAt: createdAt ?? this.createdAt,
      );
  SearchHistory copyWithCompanion(SearchHistoriesCompanion data) {
    return SearchHistory(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistory(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, query, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistory &&
          other.id == this.id &&
          other.query == this.query &&
          other.createdAt == this.createdAt);
}

class SearchHistoriesCompanion extends UpdateCompanion<SearchHistory> {
  final Value<int> id;
  final Value<String> query;
  final Value<String> createdAt;
  const SearchHistoriesCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SearchHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String query,
    this.createdAt = const Value.absent(),
  }) : query = Value(query);
  static Insertable<SearchHistory> custom({
    Expression<int>? id,
    Expression<String>? query,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SearchHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? query,
    Value<String>? createdAt,
  }) {
    return SearchHistoriesCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadJobsTable extends DownloadJobs
    with TableInfo<$DownloadJobsTable, DownloadJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _comicIdMeta = const VerificationMeta(
    'comicId',
  );
  @override
  late final GeneratedColumn<String> comicId = GeneratedColumn<String>(
    'comic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedPagesMeta = const VerificationMeta(
    'completedPages',
  );
  @override
  late final GeneratedColumn<int> completedPages = GeneratedColumn<int>(
    'completed_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextPageNumberMeta = const VerificationMeta(
    'nextPageNumber',
  );
  @override
  late final GeneratedColumn<int> nextPageNumber = GeneratedColumn<int>(
    'next_page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<String> requestedAt = GeneratedColumn<String>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    comicId,
    mediaId,
    title,
    thumbnailPath,
    status,
    totalPages,
    completedPages,
    nextPageNumber,
    requestedAt,
    startedAt,
    updatedAt,
    completedAt,
    lastError,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'DownloadJob';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('comic_id')) {
      context.handle(
        _comicIdMeta,
        comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPagesMeta);
    }
    if (data.containsKey('completed_pages')) {
      context.handle(
        _completedPagesMeta,
        completedPages.isAcceptableOrUnknown(
          data['completed_pages']!,
          _completedPagesMeta,
        ),
      );
    }
    if (data.containsKey('next_page_number')) {
      context.handle(
        _nextPageNumberMeta,
        nextPageNumber.isAcceptableOrUnknown(
          data['next_page_number']!,
          _nextPageNumberMeta,
        ),
      );
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {comicId};
  @override
  DownloadJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJob(
      comicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comic_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      completedPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_pages'],
      )!,
      nextPageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_page_number'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requested_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $DownloadJobsTable createAlias(String alias) {
    return $DownloadJobsTable(attachedDatabase, alias);
  }
}

class DownloadJob extends DataClass implements Insertable<DownloadJob> {
  final String comicId;
  final String mediaId;
  final String title;
  final String? thumbnailPath;
  final String status;
  final int totalPages;
  final int completedPages;
  final int nextPageNumber;
  final String requestedAt;
  final String? startedAt;
  final String updatedAt;
  final String? completedAt;
  final String? lastError;
  final int retryCount;
  const DownloadJob({
    required this.comicId,
    required this.mediaId,
    required this.title,
    this.thumbnailPath,
    required this.status,
    required this.totalPages,
    required this.completedPages,
    required this.nextPageNumber,
    required this.requestedAt,
    this.startedAt,
    required this.updatedAt,
    this.completedAt,
    this.lastError,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['comic_id'] = Variable<String>(comicId);
    map['media_id'] = Variable<String>(mediaId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['status'] = Variable<String>(status);
    map['total_pages'] = Variable<int>(totalPages);
    map['completed_pages'] = Variable<int>(completedPages);
    map['next_page_number'] = Variable<int>(nextPageNumber);
    map['requested_at'] = Variable<String>(requestedAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<String>(startedAt);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  DownloadJobsCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobsCompanion(
      comicId: Value(comicId),
      mediaId: Value(mediaId),
      title: Value(title),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      status: Value(status),
      totalPages: Value(totalPages),
      completedPages: Value(completedPages),
      nextPageNumber: Value(nextPageNumber),
      requestedAt: Value(requestedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      retryCount: Value(retryCount),
    );
  }

  factory DownloadJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJob(
      comicId: serializer.fromJson<String>(json['comicId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      status: serializer.fromJson<String>(json['status']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      completedPages: serializer.fromJson<int>(json['completedPages']),
      nextPageNumber: serializer.fromJson<int>(json['nextPageNumber']),
      requestedAt: serializer.fromJson<String>(json['requestedAt']),
      startedAt: serializer.fromJson<String?>(json['startedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'comicId': serializer.toJson<String>(comicId),
      'mediaId': serializer.toJson<String>(mediaId),
      'title': serializer.toJson<String>(title),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'status': serializer.toJson<String>(status),
      'totalPages': serializer.toJson<int>(totalPages),
      'completedPages': serializer.toJson<int>(completedPages),
      'nextPageNumber': serializer.toJson<int>(nextPageNumber),
      'requestedAt': serializer.toJson<String>(requestedAt),
      'startedAt': serializer.toJson<String?>(startedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  DownloadJob copyWith({
    String? comicId,
    String? mediaId,
    String? title,
    Value<String?> thumbnailPath = const Value.absent(),
    String? status,
    int? totalPages,
    int? completedPages,
    int? nextPageNumber,
    String? requestedAt,
    Value<String?> startedAt = const Value.absent(),
    String? updatedAt,
    Value<String?> completedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? retryCount,
  }) => DownloadJob(
    comicId: comicId ?? this.comicId,
    mediaId: mediaId ?? this.mediaId,
    title: title ?? this.title,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    status: status ?? this.status,
    totalPages: totalPages ?? this.totalPages,
    completedPages: completedPages ?? this.completedPages,
    nextPageNumber: nextPageNumber ?? this.nextPageNumber,
    requestedAt: requestedAt ?? this.requestedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    retryCount: retryCount ?? this.retryCount,
  );
  DownloadJob copyWithCompanion(DownloadJobsCompanion data) {
    return DownloadJob(
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      title: data.title.present ? data.title.value : this.title,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      status: data.status.present ? data.status.value : this.status,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      completedPages: data.completedPages.present
          ? data.completedPages.value
          : this.completedPages,
      nextPageNumber: data.nextPageNumber.present
          ? data.nextPageNumber.value
          : this.nextPageNumber,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJob(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('status: $status, ')
          ..write('totalPages: $totalPages, ')
          ..write('completedPages: $completedPages, ')
          ..write('nextPageNumber: $nextPageNumber, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    comicId,
    mediaId,
    title,
    thumbnailPath,
    status,
    totalPages,
    completedPages,
    nextPageNumber,
    requestedAt,
    startedAt,
    updatedAt,
    completedAt,
    lastError,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJob &&
          other.comicId == this.comicId &&
          other.mediaId == this.mediaId &&
          other.title == this.title &&
          other.thumbnailPath == this.thumbnailPath &&
          other.status == this.status &&
          other.totalPages == this.totalPages &&
          other.completedPages == this.completedPages &&
          other.nextPageNumber == this.nextPageNumber &&
          other.requestedAt == this.requestedAt &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.lastError == this.lastError &&
          other.retryCount == this.retryCount);
}

class DownloadJobsCompanion extends UpdateCompanion<DownloadJob> {
  final Value<String> comicId;
  final Value<String> mediaId;
  final Value<String> title;
  final Value<String?> thumbnailPath;
  final Value<String> status;
  final Value<int> totalPages;
  final Value<int> completedPages;
  final Value<int> nextPageNumber;
  final Value<String> requestedAt;
  final Value<String?> startedAt;
  final Value<String> updatedAt;
  final Value<String?> completedAt;
  final Value<String?> lastError;
  final Value<int> retryCount;
  final Value<int> rowid;
  const DownloadJobsCompanion({
    this.comicId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.status = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.completedPages = const Value.absent(),
    this.nextPageNumber = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadJobsCompanion.insert({
    required String comicId,
    required String mediaId,
    required String title,
    this.thumbnailPath = const Value.absent(),
    required String status,
    required int totalPages,
    this.completedPages = const Value.absent(),
    this.nextPageNumber = const Value.absent(),
    required String requestedAt,
    this.startedAt = const Value.absent(),
    required String updatedAt,
    this.completedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : comicId = Value(comicId),
       mediaId = Value(mediaId),
       title = Value(title),
       status = Value(status),
       totalPages = Value(totalPages),
       requestedAt = Value(requestedAt),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadJob> custom({
    Expression<String>? comicId,
    Expression<String>? mediaId,
    Expression<String>? title,
    Expression<String>? thumbnailPath,
    Expression<String>? status,
    Expression<int>? totalPages,
    Expression<int>? completedPages,
    Expression<int>? nextPageNumber,
    Expression<String>? requestedAt,
    Expression<String>? startedAt,
    Expression<String>? updatedAt,
    Expression<String>? completedAt,
    Expression<String>? lastError,
    Expression<int>? retryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (comicId != null) 'comic_id': comicId,
      if (mediaId != null) 'media_id': mediaId,
      if (title != null) 'title': title,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (status != null) 'status': status,
      if (totalPages != null) 'total_pages': totalPages,
      if (completedPages != null) 'completed_pages': completedPages,
      if (nextPageNumber != null) 'next_page_number': nextPageNumber,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (lastError != null) 'last_error': lastError,
      if (retryCount != null) 'retry_count': retryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadJobsCompanion copyWith({
    Value<String>? comicId,
    Value<String>? mediaId,
    Value<String>? title,
    Value<String?>? thumbnailPath,
    Value<String>? status,
    Value<int>? totalPages,
    Value<int>? completedPages,
    Value<int>? nextPageNumber,
    Value<String>? requestedAt,
    Value<String?>? startedAt,
    Value<String>? updatedAt,
    Value<String?>? completedAt,
    Value<String?>? lastError,
    Value<int>? retryCount,
    Value<int>? rowid,
  }) {
    return DownloadJobsCompanion(
      comicId: comicId ?? this.comicId,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      totalPages: totalPages ?? this.totalPages,
      completedPages: completedPages ?? this.completedPages,
      nextPageNumber: nextPageNumber ?? this.nextPageNumber,
      requestedAt: requestedAt ?? this.requestedAt,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      lastError: lastError ?? this.lastError,
      retryCount: retryCount ?? this.retryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (comicId.present) {
      map['comic_id'] = Variable<String>(comicId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (completedPages.present) {
      map['completed_pages'] = Variable<int>(completedPages.value);
    }
    if (nextPageNumber.present) {
      map['next_page_number'] = Variable<int>(nextPageNumber.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<String>(requestedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobsCompanion(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('status: $status, ')
          ..write('totalPages: $totalPages, ')
          ..write('completedPages: $completedPages, ')
          ..write('nextPageNumber: $nextPageNumber, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadJobPagesTable extends DownloadJobPages
    with TableInfo<$DownloadJobPagesTable, DownloadJobPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _comicIdMeta = const VerificationMeta(
    'comicId',
  );
  @override
  late final GeneratedColumn<String> comicId = GeneratedColumn<String>(
    'comic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceServerMeta = const VerificationMeta(
    'sourceServer',
  );
  @override
  late final GeneratedColumn<String> sourceServer = GeneratedColumn<String>(
    'source_server',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storedFormatMeta = const VerificationMeta(
    'storedFormat',
  );
  @override
  late final GeneratedColumn<String> storedFormat = GeneratedColumn<String>(
    'stored_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<String> downloadedAt = GeneratedColumn<String>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    comicId,
    mediaId,
    pageNumber,
    remotePath,
    sourceServer,
    localPath,
    storedFormat,
    byteSize,
    status,
    downloadedAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'DownloadJobPage';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadJobPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('comic_id')) {
      context.handle(
        _comicIdMeta,
        comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('source_server')) {
      context.handle(
        _sourceServerMeta,
        sourceServer.isAcceptableOrUnknown(
          data['source_server']!,
          _sourceServerMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('stored_format')) {
      context.handle(
        _storedFormatMeta,
        storedFormat.isAcceptableOrUnknown(
          data['stored_format']!,
          _storedFormatMeta,
        ),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {comicId, pageNumber};
  @override
  DownloadJobPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJobPage(
      comicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comic_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      sourceServer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_server'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      storedFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_format'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloaded_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $DownloadJobPagesTable createAlias(String alias) {
    return $DownloadJobPagesTable(attachedDatabase, alias);
  }
}

class DownloadJobPage extends DataClass implements Insertable<DownloadJobPage> {
  final String comicId;
  final String mediaId;
  final int pageNumber;
  final String remotePath;
  final String? sourceServer;
  final String? localPath;
  final String? storedFormat;
  final int? byteSize;
  final String status;
  final String? downloadedAt;
  final String? lastError;
  const DownloadJobPage({
    required this.comicId,
    required this.mediaId,
    required this.pageNumber,
    required this.remotePath,
    this.sourceServer,
    this.localPath,
    this.storedFormat,
    this.byteSize,
    required this.status,
    this.downloadedAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['comic_id'] = Variable<String>(comicId);
    map['media_id'] = Variable<String>(mediaId);
    map['page_number'] = Variable<int>(pageNumber);
    map['remote_path'] = Variable<String>(remotePath);
    if (!nullToAbsent || sourceServer != null) {
      map['source_server'] = Variable<String>(sourceServer);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || storedFormat != null) {
      map['stored_format'] = Variable<String>(storedFormat);
    }
    if (!nullToAbsent || byteSize != null) {
      map['byte_size'] = Variable<int>(byteSize);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<String>(downloadedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  DownloadJobPagesCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobPagesCompanion(
      comicId: Value(comicId),
      mediaId: Value(mediaId),
      pageNumber: Value(pageNumber),
      remotePath: Value(remotePath),
      sourceServer: sourceServer == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceServer),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      storedFormat: storedFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(storedFormat),
      byteSize: byteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(byteSize),
      status: Value(status),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory DownloadJobPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJobPage(
      comicId: serializer.fromJson<String>(json['comicId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      sourceServer: serializer.fromJson<String?>(json['sourceServer']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      storedFormat: serializer.fromJson<String?>(json['storedFormat']),
      byteSize: serializer.fromJson<int?>(json['byteSize']),
      status: serializer.fromJson<String>(json['status']),
      downloadedAt: serializer.fromJson<String?>(json['downloadedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'comicId': serializer.toJson<String>(comicId),
      'mediaId': serializer.toJson<String>(mediaId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'remotePath': serializer.toJson<String>(remotePath),
      'sourceServer': serializer.toJson<String?>(sourceServer),
      'localPath': serializer.toJson<String?>(localPath),
      'storedFormat': serializer.toJson<String?>(storedFormat),
      'byteSize': serializer.toJson<int?>(byteSize),
      'status': serializer.toJson<String>(status),
      'downloadedAt': serializer.toJson<String?>(downloadedAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  DownloadJobPage copyWith({
    String? comicId,
    String? mediaId,
    int? pageNumber,
    String? remotePath,
    Value<String?> sourceServer = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> storedFormat = const Value.absent(),
    Value<int?> byteSize = const Value.absent(),
    String? status,
    Value<String?> downloadedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => DownloadJobPage(
    comicId: comicId ?? this.comicId,
    mediaId: mediaId ?? this.mediaId,
    pageNumber: pageNumber ?? this.pageNumber,
    remotePath: remotePath ?? this.remotePath,
    sourceServer: sourceServer.present ? sourceServer.value : this.sourceServer,
    localPath: localPath.present ? localPath.value : this.localPath,
    storedFormat: storedFormat.present ? storedFormat.value : this.storedFormat,
    byteSize: byteSize.present ? byteSize.value : this.byteSize,
    status: status ?? this.status,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  DownloadJobPage copyWithCompanion(DownloadJobPagesCompanion data) {
    return DownloadJobPage(
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      sourceServer: data.sourceServer.present
          ? data.sourceServer.value
          : this.sourceServer,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      storedFormat: data.storedFormat.present
          ? data.storedFormat.value
          : this.storedFormat,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      status: data.status.present ? data.status.value : this.status,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobPage(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('remotePath: $remotePath, ')
          ..write('sourceServer: $sourceServer, ')
          ..write('localPath: $localPath, ')
          ..write('storedFormat: $storedFormat, ')
          ..write('byteSize: $byteSize, ')
          ..write('status: $status, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    comicId,
    mediaId,
    pageNumber,
    remotePath,
    sourceServer,
    localPath,
    storedFormat,
    byteSize,
    status,
    downloadedAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJobPage &&
          other.comicId == this.comicId &&
          other.mediaId == this.mediaId &&
          other.pageNumber == this.pageNumber &&
          other.remotePath == this.remotePath &&
          other.sourceServer == this.sourceServer &&
          other.localPath == this.localPath &&
          other.storedFormat == this.storedFormat &&
          other.byteSize == this.byteSize &&
          other.status == this.status &&
          other.downloadedAt == this.downloadedAt &&
          other.lastError == this.lastError);
}

class DownloadJobPagesCompanion extends UpdateCompanion<DownloadJobPage> {
  final Value<String> comicId;
  final Value<String> mediaId;
  final Value<int> pageNumber;
  final Value<String> remotePath;
  final Value<String?> sourceServer;
  final Value<String?> localPath;
  final Value<String?> storedFormat;
  final Value<int?> byteSize;
  final Value<String> status;
  final Value<String?> downloadedAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const DownloadJobPagesCompanion({
    this.comicId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.sourceServer = const Value.absent(),
    this.localPath = const Value.absent(),
    this.storedFormat = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.status = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadJobPagesCompanion.insert({
    required String comicId,
    required String mediaId,
    required int pageNumber,
    required String remotePath,
    this.sourceServer = const Value.absent(),
    this.localPath = const Value.absent(),
    this.storedFormat = const Value.absent(),
    this.byteSize = const Value.absent(),
    required String status,
    this.downloadedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : comicId = Value(comicId),
       mediaId = Value(mediaId),
       pageNumber = Value(pageNumber),
       remotePath = Value(remotePath),
       status = Value(status);
  static Insertable<DownloadJobPage> custom({
    Expression<String>? comicId,
    Expression<String>? mediaId,
    Expression<int>? pageNumber,
    Expression<String>? remotePath,
    Expression<String>? sourceServer,
    Expression<String>? localPath,
    Expression<String>? storedFormat,
    Expression<int>? byteSize,
    Expression<String>? status,
    Expression<String>? downloadedAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (comicId != null) 'comic_id': comicId,
      if (mediaId != null) 'media_id': mediaId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (remotePath != null) 'remote_path': remotePath,
      if (sourceServer != null) 'source_server': sourceServer,
      if (localPath != null) 'local_path': localPath,
      if (storedFormat != null) 'stored_format': storedFormat,
      if (byteSize != null) 'byte_size': byteSize,
      if (status != null) 'status': status,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadJobPagesCompanion copyWith({
    Value<String>? comicId,
    Value<String>? mediaId,
    Value<int>? pageNumber,
    Value<String>? remotePath,
    Value<String?>? sourceServer,
    Value<String?>? localPath,
    Value<String?>? storedFormat,
    Value<int?>? byteSize,
    Value<String>? status,
    Value<String?>? downloadedAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return DownloadJobPagesCompanion(
      comicId: comicId ?? this.comicId,
      mediaId: mediaId ?? this.mediaId,
      pageNumber: pageNumber ?? this.pageNumber,
      remotePath: remotePath ?? this.remotePath,
      sourceServer: sourceServer ?? this.sourceServer,
      localPath: localPath ?? this.localPath,
      storedFormat: storedFormat ?? this.storedFormat,
      byteSize: byteSize ?? this.byteSize,
      status: status ?? this.status,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (comicId.present) {
      map['comic_id'] = Variable<String>(comicId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (sourceServer.present) {
      map['source_server'] = Variable<String>(sourceServer.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (storedFormat.present) {
      map['stored_format'] = Variable<String>(storedFormat.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<String>(downloadedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobPagesCompanion(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('remotePath: $remotePath, ')
          ..write('sourceServer: $sourceServer, ')
          ..write('localPath: $localPath, ')
          ..write('storedFormat: $storedFormat, ')
          ..write('byteSize: $byteSize, ')
          ..write('status: $status, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadedComicsTable extends DownloadedComics
    with TableInfo<$DownloadedComicsTable, DownloadedComic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedComicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _comicIdMeta = const VerificationMeta(
    'comicId',
  );
  @override
  late final GeneratedColumn<String> comicId = GeneratedColumn<String>(
    'comic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEnglishMeta = const VerificationMeta(
    'titleEnglish',
  );
  @override
  late final GeneratedColumn<String> titleEnglish = GeneratedColumn<String>(
    'title_english',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleJapaneseMeta = const VerificationMeta(
    'titleJapanese',
  );
  @override
  late final GeneratedColumn<String> titleJapanese = GeneratedColumn<String>(
    'title_japanese',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titlePrettyMeta = const VerificationMeta(
    'titlePretty',
  );
  @override
  late final GeneratedColumn<String> titlePretty = GeneratedColumn<String>(
    'title_pretty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverLocalPathMeta = const VerificationMeta(
    'coverLocalPath',
  );
  @override
  late final GeneratedColumn<String> coverLocalPath = GeneratedColumn<String>(
    'cover_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootDirectoryPathMeta = const VerificationMeta(
    'rootDirectoryPath',
  );
  @override
  late final GeneratedColumn<String> rootDirectoryPath =
      GeneratedColumn<String>(
        'root_directory_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<String> downloadedAt = GeneratedColumn<String>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<String> lastReadAt = GeneratedColumn<String>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numFavoritesMeta = const VerificationMeta(
    'numFavorites',
  );
  @override
  late final GeneratedColumn<int> numFavorites = GeneratedColumn<int>(
    'num_favorites',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    comicId,
    mediaId,
    titleEnglish,
    titleJapanese,
    titlePretty,
    coverLocalPath,
    rootDirectoryPath,
    pageCount,
    downloadedAt,
    lastReadAt,
    numFavorites,
    tagsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'DownloadedComic';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedComic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('comic_id')) {
      context.handle(
        _comicIdMeta,
        comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('title_english')) {
      context.handle(
        _titleEnglishMeta,
        titleEnglish.isAcceptableOrUnknown(
          data['title_english']!,
          _titleEnglishMeta,
        ),
      );
    }
    if (data.containsKey('title_japanese')) {
      context.handle(
        _titleJapaneseMeta,
        titleJapanese.isAcceptableOrUnknown(
          data['title_japanese']!,
          _titleJapaneseMeta,
        ),
      );
    }
    if (data.containsKey('title_pretty')) {
      context.handle(
        _titlePrettyMeta,
        titlePretty.isAcceptableOrUnknown(
          data['title_pretty']!,
          _titlePrettyMeta,
        ),
      );
    }
    if (data.containsKey('cover_local_path')) {
      context.handle(
        _coverLocalPathMeta,
        coverLocalPath.isAcceptableOrUnknown(
          data['cover_local_path']!,
          _coverLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('root_directory_path')) {
      context.handle(
        _rootDirectoryPathMeta,
        rootDirectoryPath.isAcceptableOrUnknown(
          data['root_directory_path']!,
          _rootDirectoryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rootDirectoryPathMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('num_favorites')) {
      context.handle(
        _numFavoritesMeta,
        numFavorites.isAcceptableOrUnknown(
          data['num_favorites']!,
          _numFavoritesMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {comicId};
  @override
  DownloadedComic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedComic(
      comicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comic_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      titleEnglish: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_english'],
      ),
      titleJapanese: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_japanese'],
      ),
      titlePretty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_pretty'],
      ),
      coverLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_local_path'],
      ),
      rootDirectoryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_directory_path'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloaded_at'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_at'],
      ),
      numFavorites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num_favorites'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
    );
  }

  @override
  $DownloadedComicsTable createAlias(String alias) {
    return $DownloadedComicsTable(attachedDatabase, alias);
  }
}

class DownloadedComic extends DataClass implements Insertable<DownloadedComic> {
  final String comicId;
  final String mediaId;
  final String? titleEnglish;
  final String? titleJapanese;
  final String? titlePretty;
  final String? coverLocalPath;
  final String rootDirectoryPath;
  final int pageCount;
  final String downloadedAt;
  final String? lastReadAt;
  final int? numFavorites;
  final String tagsJson;
  const DownloadedComic({
    required this.comicId,
    required this.mediaId,
    this.titleEnglish,
    this.titleJapanese,
    this.titlePretty,
    this.coverLocalPath,
    required this.rootDirectoryPath,
    required this.pageCount,
    required this.downloadedAt,
    this.lastReadAt,
    this.numFavorites,
    required this.tagsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['comic_id'] = Variable<String>(comicId);
    map['media_id'] = Variable<String>(mediaId);
    if (!nullToAbsent || titleEnglish != null) {
      map['title_english'] = Variable<String>(titleEnglish);
    }
    if (!nullToAbsent || titleJapanese != null) {
      map['title_japanese'] = Variable<String>(titleJapanese);
    }
    if (!nullToAbsent || titlePretty != null) {
      map['title_pretty'] = Variable<String>(titlePretty);
    }
    if (!nullToAbsent || coverLocalPath != null) {
      map['cover_local_path'] = Variable<String>(coverLocalPath);
    }
    map['root_directory_path'] = Variable<String>(rootDirectoryPath);
    map['page_count'] = Variable<int>(pageCount);
    map['downloaded_at'] = Variable<String>(downloadedAt);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(lastReadAt);
    }
    if (!nullToAbsent || numFavorites != null) {
      map['num_favorites'] = Variable<int>(numFavorites);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    return map;
  }

  DownloadedComicsCompanion toCompanion(bool nullToAbsent) {
    return DownloadedComicsCompanion(
      comicId: Value(comicId),
      mediaId: Value(mediaId),
      titleEnglish: titleEnglish == null && nullToAbsent
          ? const Value.absent()
          : Value(titleEnglish),
      titleJapanese: titleJapanese == null && nullToAbsent
          ? const Value.absent()
          : Value(titleJapanese),
      titlePretty: titlePretty == null && nullToAbsent
          ? const Value.absent()
          : Value(titlePretty),
      coverLocalPath: coverLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLocalPath),
      rootDirectoryPath: Value(rootDirectoryPath),
      pageCount: Value(pageCount),
      downloadedAt: Value(downloadedAt),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      numFavorites: numFavorites == null && nullToAbsent
          ? const Value.absent()
          : Value(numFavorites),
      tagsJson: Value(tagsJson),
    );
  }

  factory DownloadedComic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedComic(
      comicId: serializer.fromJson<String>(json['comicId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      titleEnglish: serializer.fromJson<String?>(json['titleEnglish']),
      titleJapanese: serializer.fromJson<String?>(json['titleJapanese']),
      titlePretty: serializer.fromJson<String?>(json['titlePretty']),
      coverLocalPath: serializer.fromJson<String?>(json['coverLocalPath']),
      rootDirectoryPath: serializer.fromJson<String>(json['rootDirectoryPath']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      downloadedAt: serializer.fromJson<String>(json['downloadedAt']),
      lastReadAt: serializer.fromJson<String?>(json['lastReadAt']),
      numFavorites: serializer.fromJson<int?>(json['numFavorites']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'comicId': serializer.toJson<String>(comicId),
      'mediaId': serializer.toJson<String>(mediaId),
      'titleEnglish': serializer.toJson<String?>(titleEnglish),
      'titleJapanese': serializer.toJson<String?>(titleJapanese),
      'titlePretty': serializer.toJson<String?>(titlePretty),
      'coverLocalPath': serializer.toJson<String?>(coverLocalPath),
      'rootDirectoryPath': serializer.toJson<String>(rootDirectoryPath),
      'pageCount': serializer.toJson<int>(pageCount),
      'downloadedAt': serializer.toJson<String>(downloadedAt),
      'lastReadAt': serializer.toJson<String?>(lastReadAt),
      'numFavorites': serializer.toJson<int?>(numFavorites),
      'tagsJson': serializer.toJson<String>(tagsJson),
    };
  }

  DownloadedComic copyWith({
    String? comicId,
    String? mediaId,
    Value<String?> titleEnglish = const Value.absent(),
    Value<String?> titleJapanese = const Value.absent(),
    Value<String?> titlePretty = const Value.absent(),
    Value<String?> coverLocalPath = const Value.absent(),
    String? rootDirectoryPath,
    int? pageCount,
    String? downloadedAt,
    Value<String?> lastReadAt = const Value.absent(),
    Value<int?> numFavorites = const Value.absent(),
    String? tagsJson,
  }) => DownloadedComic(
    comicId: comicId ?? this.comicId,
    mediaId: mediaId ?? this.mediaId,
    titleEnglish: titleEnglish.present ? titleEnglish.value : this.titleEnglish,
    titleJapanese: titleJapanese.present
        ? titleJapanese.value
        : this.titleJapanese,
    titlePretty: titlePretty.present ? titlePretty.value : this.titlePretty,
    coverLocalPath: coverLocalPath.present
        ? coverLocalPath.value
        : this.coverLocalPath,
    rootDirectoryPath: rootDirectoryPath ?? this.rootDirectoryPath,
    pageCount: pageCount ?? this.pageCount,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    numFavorites: numFavorites.present ? numFavorites.value : this.numFavorites,
    tagsJson: tagsJson ?? this.tagsJson,
  );
  DownloadedComic copyWithCompanion(DownloadedComicsCompanion data) {
    return DownloadedComic(
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      titleEnglish: data.titleEnglish.present
          ? data.titleEnglish.value
          : this.titleEnglish,
      titleJapanese: data.titleJapanese.present
          ? data.titleJapanese.value
          : this.titleJapanese,
      titlePretty: data.titlePretty.present
          ? data.titlePretty.value
          : this.titlePretty,
      coverLocalPath: data.coverLocalPath.present
          ? data.coverLocalPath.value
          : this.coverLocalPath,
      rootDirectoryPath: data.rootDirectoryPath.present
          ? data.rootDirectoryPath.value
          : this.rootDirectoryPath,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      numFavorites: data.numFavorites.present
          ? data.numFavorites.value
          : this.numFavorites,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedComic(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('titleEnglish: $titleEnglish, ')
          ..write('titleJapanese: $titleJapanese, ')
          ..write('titlePretty: $titlePretty, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('rootDirectoryPath: $rootDirectoryPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('numFavorites: $numFavorites, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    comicId,
    mediaId,
    titleEnglish,
    titleJapanese,
    titlePretty,
    coverLocalPath,
    rootDirectoryPath,
    pageCount,
    downloadedAt,
    lastReadAt,
    numFavorites,
    tagsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedComic &&
          other.comicId == this.comicId &&
          other.mediaId == this.mediaId &&
          other.titleEnglish == this.titleEnglish &&
          other.titleJapanese == this.titleJapanese &&
          other.titlePretty == this.titlePretty &&
          other.coverLocalPath == this.coverLocalPath &&
          other.rootDirectoryPath == this.rootDirectoryPath &&
          other.pageCount == this.pageCount &&
          other.downloadedAt == this.downloadedAt &&
          other.lastReadAt == this.lastReadAt &&
          other.numFavorites == this.numFavorites &&
          other.tagsJson == this.tagsJson);
}

class DownloadedComicsCompanion extends UpdateCompanion<DownloadedComic> {
  final Value<String> comicId;
  final Value<String> mediaId;
  final Value<String?> titleEnglish;
  final Value<String?> titleJapanese;
  final Value<String?> titlePretty;
  final Value<String?> coverLocalPath;
  final Value<String> rootDirectoryPath;
  final Value<int> pageCount;
  final Value<String> downloadedAt;
  final Value<String?> lastReadAt;
  final Value<int?> numFavorites;
  final Value<String> tagsJson;
  final Value<int> rowid;
  const DownloadedComicsCompanion({
    this.comicId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.titleEnglish = const Value.absent(),
    this.titleJapanese = const Value.absent(),
    this.titlePretty = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.rootDirectoryPath = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.numFavorites = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedComicsCompanion.insert({
    required String comicId,
    required String mediaId,
    this.titleEnglish = const Value.absent(),
    this.titleJapanese = const Value.absent(),
    this.titlePretty = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    required String rootDirectoryPath,
    required int pageCount,
    required String downloadedAt,
    this.lastReadAt = const Value.absent(),
    this.numFavorites = const Value.absent(),
    required String tagsJson,
    this.rowid = const Value.absent(),
  }) : comicId = Value(comicId),
       mediaId = Value(mediaId),
       rootDirectoryPath = Value(rootDirectoryPath),
       pageCount = Value(pageCount),
       downloadedAt = Value(downloadedAt),
       tagsJson = Value(tagsJson);
  static Insertable<DownloadedComic> custom({
    Expression<String>? comicId,
    Expression<String>? mediaId,
    Expression<String>? titleEnglish,
    Expression<String>? titleJapanese,
    Expression<String>? titlePretty,
    Expression<String>? coverLocalPath,
    Expression<String>? rootDirectoryPath,
    Expression<int>? pageCount,
    Expression<String>? downloadedAt,
    Expression<String>? lastReadAt,
    Expression<int>? numFavorites,
    Expression<String>? tagsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (comicId != null) 'comic_id': comicId,
      if (mediaId != null) 'media_id': mediaId,
      if (titleEnglish != null) 'title_english': titleEnglish,
      if (titleJapanese != null) 'title_japanese': titleJapanese,
      if (titlePretty != null) 'title_pretty': titlePretty,
      if (coverLocalPath != null) 'cover_local_path': coverLocalPath,
      if (rootDirectoryPath != null) 'root_directory_path': rootDirectoryPath,
      if (pageCount != null) 'page_count': pageCount,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (numFavorites != null) 'num_favorites': numFavorites,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedComicsCompanion copyWith({
    Value<String>? comicId,
    Value<String>? mediaId,
    Value<String?>? titleEnglish,
    Value<String?>? titleJapanese,
    Value<String?>? titlePretty,
    Value<String?>? coverLocalPath,
    Value<String>? rootDirectoryPath,
    Value<int>? pageCount,
    Value<String>? downloadedAt,
    Value<String?>? lastReadAt,
    Value<int?>? numFavorites,
    Value<String>? tagsJson,
    Value<int>? rowid,
  }) {
    return DownloadedComicsCompanion(
      comicId: comicId ?? this.comicId,
      mediaId: mediaId ?? this.mediaId,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      titleJapanese: titleJapanese ?? this.titleJapanese,
      titlePretty: titlePretty ?? this.titlePretty,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      rootDirectoryPath: rootDirectoryPath ?? this.rootDirectoryPath,
      pageCount: pageCount ?? this.pageCount,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      numFavorites: numFavorites ?? this.numFavorites,
      tagsJson: tagsJson ?? this.tagsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (comicId.present) {
      map['comic_id'] = Variable<String>(comicId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (titleEnglish.present) {
      map['title_english'] = Variable<String>(titleEnglish.value);
    }
    if (titleJapanese.present) {
      map['title_japanese'] = Variable<String>(titleJapanese.value);
    }
    if (titlePretty.present) {
      map['title_pretty'] = Variable<String>(titlePretty.value);
    }
    if (coverLocalPath.present) {
      map['cover_local_path'] = Variable<String>(coverLocalPath.value);
    }
    if (rootDirectoryPath.present) {
      map['root_directory_path'] = Variable<String>(rootDirectoryPath.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<String>(downloadedAt.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(lastReadAt.value);
    }
    if (numFavorites.present) {
      map['num_favorites'] = Variable<int>(numFavorites.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedComicsCompanion(')
          ..write('comicId: $comicId, ')
          ..write('mediaId: $mediaId, ')
          ..write('titleEnglish: $titleEnglish, ')
          ..write('titleJapanese: $titleJapanese, ')
          ..write('titlePretty: $titlePretty, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('rootDirectoryPath: $rootDirectoryPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('numFavorites: $numFavorites, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $AppOptionsTable appOptions = $AppOptionsTable(this);
  late final $ComicsTable comics = $ComicsTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $SearchHistoriesTable searchHistories = $SearchHistoriesTable(
    this,
  );
  late final $DownloadJobsTable downloadJobs = $DownloadJobsTable(this);
  late final $DownloadJobPagesTable downloadJobPages = $DownloadJobPagesTable(
    this,
  );
  late final $DownloadedComicsTable downloadedComics = $DownloadedComicsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appOptions,
    comics,
    collections,
    searchHistories,
    downloadJobs,
    downloadJobPages,
    downloadedComics,
  ];
}

typedef $$AppOptionsTableCreateCompanionBuilder =
    AppOptionsCompanion Function({
      Value<int> id,
      required String name,
      required String value,
    });
typedef $$AppOptionsTableUpdateCompanionBuilder =
    AppOptionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> value,
    });

class $$AppOptionsTableFilterComposer
    extends Composer<_$LocalDatabase, $AppOptionsTable> {
  $$AppOptionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppOptionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppOptionsTable> {
  $$AppOptionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppOptionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppOptionsTable> {
  $$AppOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppOptionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AppOptionsTable,
          AppOption,
          $$AppOptionsTableFilterComposer,
          $$AppOptionsTableOrderingComposer,
          $$AppOptionsTableAnnotationComposer,
          $$AppOptionsTableCreateCompanionBuilder,
          $$AppOptionsTableUpdateCompanionBuilder,
          (
            AppOption,
            BaseReferences<_$LocalDatabase, $AppOptionsTable, AppOption>,
          ),
          AppOption,
          PrefetchHooks Function()
        > {
  $$AppOptionsTableTableManager(_$LocalDatabase db, $AppOptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => AppOptionsCompanion(id: id, name: name, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String value,
              }) =>
                  AppOptionsCompanion.insert(id: id, name: name, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AppOptionsTable,
      AppOption,
      $$AppOptionsTableFilterComposer,
      $$AppOptionsTableOrderingComposer,
      $$AppOptionsTableAnnotationComposer,
      $$AppOptionsTableCreateCompanionBuilder,
      $$AppOptionsTableUpdateCompanionBuilder,
      (AppOption, BaseReferences<_$LocalDatabase, $AppOptionsTable, AppOption>),
      AppOption,
      PrefetchHooks Function()
    >;
typedef $$ComicsTableCreateCompanionBuilder =
    ComicsCompanion Function({
      required String id,
      required String mid,
      required String title,
      required String images,
      required int pages,
      Value<int> rowid,
    });
typedef $$ComicsTableUpdateCompanionBuilder =
    ComicsCompanion Function({
      Value<String> id,
      Value<String> mid,
      Value<String> title,
      Value<String> images,
      Value<int> pages,
      Value<int> rowid,
    });

class $$ComicsTableFilterComposer
    extends Composer<_$LocalDatabase, $ComicsTable> {
  $$ComicsTableFilterComposer({
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

  ColumnFilters<String> get mid => $composableBuilder(
    column: $table.mid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComicsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ComicsTable> {
  $$ComicsTableOrderingComposer({
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

  ColumnOrderings<String> get mid => $composableBuilder(
    column: $table.mid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComicsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ComicsTable> {
  $$ComicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mid =>
      $composableBuilder(column: $table.mid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<int> get pages =>
      $composableBuilder(column: $table.pages, builder: (column) => column);
}

class $$ComicsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ComicsTable,
          Comic,
          $$ComicsTableFilterComposer,
          $$ComicsTableOrderingComposer,
          $$ComicsTableAnnotationComposer,
          $$ComicsTableCreateCompanionBuilder,
          $$ComicsTableUpdateCompanionBuilder,
          (Comic, BaseReferences<_$LocalDatabase, $ComicsTable, Comic>),
          Comic,
          PrefetchHooks Function()
        > {
  $$ComicsTableTableManager(_$LocalDatabase db, $ComicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> images = const Value.absent(),
                Value<int> pages = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComicsCompanion(
                id: id,
                mid: mid,
                title: title,
                images: images,
                pages: pages,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mid,
                required String title,
                required String images,
                required int pages,
                Value<int> rowid = const Value.absent(),
              }) => ComicsCompanion.insert(
                id: id,
                mid: mid,
                title: title,
                images: images,
                pages: pages,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComicsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ComicsTable,
      Comic,
      $$ComicsTableFilterComposer,
      $$ComicsTableOrderingComposer,
      $$ComicsTableAnnotationComposer,
      $$ComicsTableCreateCompanionBuilder,
      $$ComicsTableUpdateCompanionBuilder,
      (Comic, BaseReferences<_$LocalDatabase, $ComicsTable, Comic>),
      Comic,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String name,
      required String comicid,
      required String dateCreated,
      Value<int?> favoriteRank,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> name,
      Value<String> comicid,
      Value<String> dateCreated,
      Value<int?> favoriteRank,
      Value<int> rowid,
    });

class $$CollectionsTableFilterComposer
    extends Composer<_$LocalDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comicid => $composableBuilder(
    column: $table.comicid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get favoriteRank => $composableBuilder(
    column: $table.favoriteRank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comicid => $composableBuilder(
    column: $table.comicid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get favoriteRank => $composableBuilder(
    column: $table.favoriteRank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get comicid =>
      $composableBuilder(column: $table.comicid, builder: (column) => column);

  GeneratedColumn<String> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get favoriteRank => $composableBuilder(
    column: $table.favoriteRank,
    builder: (column) => column,
  );
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (
            Collection,
            BaseReferences<_$LocalDatabase, $CollectionsTable, Collection>,
          ),
          Collection,
          PrefetchHooks Function()
        > {
  $$CollectionsTableTableManager(_$LocalDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> comicid = const Value.absent(),
                Value<String> dateCreated = const Value.absent(),
                Value<int?> favoriteRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                name: name,
                comicid: comicid,
                dateCreated: dateCreated,
                favoriteRank: favoriteRank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String comicid,
                required String dateCreated,
                Value<int?> favoriteRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                name: name,
                comicid: comicid,
                dateCreated: dateCreated,
                favoriteRank: favoriteRank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (
        Collection,
        BaseReferences<_$LocalDatabase, $CollectionsTable, Collection>,
      ),
      Collection,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoriesTableCreateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      required String query,
      Value<String> createdAt,
    });
typedef $$SearchHistoriesTableUpdateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      Value<String> query,
      Value<String> createdAt,
    });

class $$SearchHistoriesTableFilterComposer
    extends Composer<_$LocalDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableFilterComposer({
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

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SearchHistoriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SearchHistoriesTable,
          SearchHistory,
          $$SearchHistoriesTableFilterComposer,
          $$SearchHistoriesTableOrderingComposer,
          $$SearchHistoriesTableAnnotationComposer,
          $$SearchHistoriesTableCreateCompanionBuilder,
          $$SearchHistoriesTableUpdateCompanionBuilder,
          (
            SearchHistory,
            BaseReferences<
              _$LocalDatabase,
              $SearchHistoriesTable,
              SearchHistory
            >,
          ),
          SearchHistory,
          PrefetchHooks Function()
        > {
  $$SearchHistoriesTableTableManager(
    _$LocalDatabase db,
    $SearchHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => SearchHistoriesCompanion(
                id: id,
                query: query,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String query,
                Value<String> createdAt = const Value.absent(),
              }) => SearchHistoriesCompanion.insert(
                id: id,
                query: query,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SearchHistoriesTable,
      SearchHistory,
      $$SearchHistoriesTableFilterComposer,
      $$SearchHistoriesTableOrderingComposer,
      $$SearchHistoriesTableAnnotationComposer,
      $$SearchHistoriesTableCreateCompanionBuilder,
      $$SearchHistoriesTableUpdateCompanionBuilder,
      (
        SearchHistory,
        BaseReferences<_$LocalDatabase, $SearchHistoriesTable, SearchHistory>,
      ),
      SearchHistory,
      PrefetchHooks Function()
    >;
typedef $$DownloadJobsTableCreateCompanionBuilder =
    DownloadJobsCompanion Function({
      required String comicId,
      required String mediaId,
      required String title,
      Value<String?> thumbnailPath,
      required String status,
      required int totalPages,
      Value<int> completedPages,
      Value<int> nextPageNumber,
      required String requestedAt,
      Value<String?> startedAt,
      required String updatedAt,
      Value<String?> completedAt,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<int> rowid,
    });
typedef $$DownloadJobsTableUpdateCompanionBuilder =
    DownloadJobsCompanion Function({
      Value<String> comicId,
      Value<String> mediaId,
      Value<String> title,
      Value<String?> thumbnailPath,
      Value<String> status,
      Value<int> totalPages,
      Value<int> completedPages,
      Value<int> nextPageNumber,
      Value<String> requestedAt,
      Value<String?> startedAt,
      Value<String> updatedAt,
      Value<String?> completedAt,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<int> rowid,
    });

class $$DownloadJobsTableFilterComposer
    extends Composer<_$LocalDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedPages => $composableBuilder(
    column: $table.completedPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextPageNumber => $composableBuilder(
    column: $table.nextPageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadJobsTableOrderingComposer
    extends Composer<_$LocalDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedPages => $composableBuilder(
    column: $table.completedPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextPageNumber => $composableBuilder(
    column: $table.nextPageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadJobsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get comicId =>
      $composableBuilder(column: $table.comicId, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedPages => $composableBuilder(
    column: $table.completedPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextPageNumber => $composableBuilder(
    column: $table.nextPageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$DownloadJobsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DownloadJobsTable,
          DownloadJob,
          $$DownloadJobsTableFilterComposer,
          $$DownloadJobsTableOrderingComposer,
          $$DownloadJobsTableAnnotationComposer,
          $$DownloadJobsTableCreateCompanionBuilder,
          $$DownloadJobsTableUpdateCompanionBuilder,
          (
            DownloadJob,
            BaseReferences<_$LocalDatabase, $DownloadJobsTable, DownloadJob>,
          ),
          DownloadJob,
          PrefetchHooks Function()
        > {
  $$DownloadJobsTableTableManager(_$LocalDatabase db, $DownloadJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> comicId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<int> completedPages = const Value.absent(),
                Value<int> nextPageNumber = const Value.absent(),
                Value<String> requestedAt = const Value.absent(),
                Value<String?> startedAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion(
                comicId: comicId,
                mediaId: mediaId,
                title: title,
                thumbnailPath: thumbnailPath,
                status: status,
                totalPages: totalPages,
                completedPages: completedPages,
                nextPageNumber: nextPageNumber,
                requestedAt: requestedAt,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                lastError: lastError,
                retryCount: retryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String comicId,
                required String mediaId,
                required String title,
                Value<String?> thumbnailPath = const Value.absent(),
                required String status,
                required int totalPages,
                Value<int> completedPages = const Value.absent(),
                Value<int> nextPageNumber = const Value.absent(),
                required String requestedAt,
                Value<String?> startedAt = const Value.absent(),
                required String updatedAt,
                Value<String?> completedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion.insert(
                comicId: comicId,
                mediaId: mediaId,
                title: title,
                thumbnailPath: thumbnailPath,
                status: status,
                totalPages: totalPages,
                completedPages: completedPages,
                nextPageNumber: nextPageNumber,
                requestedAt: requestedAt,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                lastError: lastError,
                retryCount: retryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DownloadJobsTable,
      DownloadJob,
      $$DownloadJobsTableFilterComposer,
      $$DownloadJobsTableOrderingComposer,
      $$DownloadJobsTableAnnotationComposer,
      $$DownloadJobsTableCreateCompanionBuilder,
      $$DownloadJobsTableUpdateCompanionBuilder,
      (
        DownloadJob,
        BaseReferences<_$LocalDatabase, $DownloadJobsTable, DownloadJob>,
      ),
      DownloadJob,
      PrefetchHooks Function()
    >;
typedef $$DownloadJobPagesTableCreateCompanionBuilder =
    DownloadJobPagesCompanion Function({
      required String comicId,
      required String mediaId,
      required int pageNumber,
      required String remotePath,
      Value<String?> sourceServer,
      Value<String?> localPath,
      Value<String?> storedFormat,
      Value<int?> byteSize,
      required String status,
      Value<String?> downloadedAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$DownloadJobPagesTableUpdateCompanionBuilder =
    DownloadJobPagesCompanion Function({
      Value<String> comicId,
      Value<String> mediaId,
      Value<int> pageNumber,
      Value<String> remotePath,
      Value<String?> sourceServer,
      Value<String?> localPath,
      Value<String?> storedFormat,
      Value<int?> byteSize,
      Value<String> status,
      Value<String?> downloadedAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$DownloadJobPagesTableFilterComposer
    extends Composer<_$LocalDatabase, $DownloadJobPagesTable> {
  $$DownloadJobPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceServer => $composableBuilder(
    column: $table.sourceServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedFormat => $composableBuilder(
    column: $table.storedFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadJobPagesTableOrderingComposer
    extends Composer<_$LocalDatabase, $DownloadJobPagesTable> {
  $$DownloadJobPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceServer => $composableBuilder(
    column: $table.sourceServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedFormat => $composableBuilder(
    column: $table.storedFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadJobPagesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DownloadJobPagesTable> {
  $$DownloadJobPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get comicId =>
      $composableBuilder(column: $table.comicId, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceServer => $composableBuilder(
    column: $table.sourceServer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get storedFormat => $composableBuilder(
    column: $table.storedFormat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$DownloadJobPagesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DownloadJobPagesTable,
          DownloadJobPage,
          $$DownloadJobPagesTableFilterComposer,
          $$DownloadJobPagesTableOrderingComposer,
          $$DownloadJobPagesTableAnnotationComposer,
          $$DownloadJobPagesTableCreateCompanionBuilder,
          $$DownloadJobPagesTableUpdateCompanionBuilder,
          (
            DownloadJobPage,
            BaseReferences<
              _$LocalDatabase,
              $DownloadJobPagesTable,
              DownloadJobPage
            >,
          ),
          DownloadJobPage,
          PrefetchHooks Function()
        > {
  $$DownloadJobPagesTableTableManager(
    _$LocalDatabase db,
    $DownloadJobPagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadJobPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadJobPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadJobPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> comicId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> remotePath = const Value.absent(),
                Value<String?> sourceServer = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> storedFormat = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> downloadedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobPagesCompanion(
                comicId: comicId,
                mediaId: mediaId,
                pageNumber: pageNumber,
                remotePath: remotePath,
                sourceServer: sourceServer,
                localPath: localPath,
                storedFormat: storedFormat,
                byteSize: byteSize,
                status: status,
                downloadedAt: downloadedAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String comicId,
                required String mediaId,
                required int pageNumber,
                required String remotePath,
                Value<String?> sourceServer = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> storedFormat = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                required String status,
                Value<String?> downloadedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobPagesCompanion.insert(
                comicId: comicId,
                mediaId: mediaId,
                pageNumber: pageNumber,
                remotePath: remotePath,
                sourceServer: sourceServer,
                localPath: localPath,
                storedFormat: storedFormat,
                byteSize: byteSize,
                status: status,
                downloadedAt: downloadedAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadJobPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DownloadJobPagesTable,
      DownloadJobPage,
      $$DownloadJobPagesTableFilterComposer,
      $$DownloadJobPagesTableOrderingComposer,
      $$DownloadJobPagesTableAnnotationComposer,
      $$DownloadJobPagesTableCreateCompanionBuilder,
      $$DownloadJobPagesTableUpdateCompanionBuilder,
      (
        DownloadJobPage,
        BaseReferences<
          _$LocalDatabase,
          $DownloadJobPagesTable,
          DownloadJobPage
        >,
      ),
      DownloadJobPage,
      PrefetchHooks Function()
    >;
typedef $$DownloadedComicsTableCreateCompanionBuilder =
    DownloadedComicsCompanion Function({
      required String comicId,
      required String mediaId,
      Value<String?> titleEnglish,
      Value<String?> titleJapanese,
      Value<String?> titlePretty,
      Value<String?> coverLocalPath,
      required String rootDirectoryPath,
      required int pageCount,
      required String downloadedAt,
      Value<String?> lastReadAt,
      Value<int?> numFavorites,
      required String tagsJson,
      Value<int> rowid,
    });
typedef $$DownloadedComicsTableUpdateCompanionBuilder =
    DownloadedComicsCompanion Function({
      Value<String> comicId,
      Value<String> mediaId,
      Value<String?> titleEnglish,
      Value<String?> titleJapanese,
      Value<String?> titlePretty,
      Value<String?> coverLocalPath,
      Value<String> rootDirectoryPath,
      Value<int> pageCount,
      Value<String> downloadedAt,
      Value<String?> lastReadAt,
      Value<int?> numFavorites,
      Value<String> tagsJson,
      Value<int> rowid,
    });

class $$DownloadedComicsTableFilterComposer
    extends Composer<_$LocalDatabase, $DownloadedComicsTable> {
  $$DownloadedComicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titlePretty => $composableBuilder(
    column: $table.titlePretty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootDirectoryPath => $composableBuilder(
    column: $table.rootDirectoryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numFavorites => $composableBuilder(
    column: $table.numFavorites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedComicsTableOrderingComposer
    extends Composer<_$LocalDatabase, $DownloadedComicsTable> {
  $$DownloadedComicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get comicId => $composableBuilder(
    column: $table.comicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titlePretty => $composableBuilder(
    column: $table.titlePretty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootDirectoryPath => $composableBuilder(
    column: $table.rootDirectoryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numFavorites => $composableBuilder(
    column: $table.numFavorites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedComicsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DownloadedComicsTable> {
  $$DownloadedComicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get comicId =>
      $composableBuilder(column: $table.comicId, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get titleEnglish => $composableBuilder(
    column: $table.titleEnglish,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleJapanese => $composableBuilder(
    column: $table.titleJapanese,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titlePretty => $composableBuilder(
    column: $table.titlePretty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rootDirectoryPath => $composableBuilder(
    column: $table.rootDirectoryPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numFavorites => $composableBuilder(
    column: $table.numFavorites,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);
}

class $$DownloadedComicsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DownloadedComicsTable,
          DownloadedComic,
          $$DownloadedComicsTableFilterComposer,
          $$DownloadedComicsTableOrderingComposer,
          $$DownloadedComicsTableAnnotationComposer,
          $$DownloadedComicsTableCreateCompanionBuilder,
          $$DownloadedComicsTableUpdateCompanionBuilder,
          (
            DownloadedComic,
            BaseReferences<
              _$LocalDatabase,
              $DownloadedComicsTable,
              DownloadedComic
            >,
          ),
          DownloadedComic,
          PrefetchHooks Function()
        > {
  $$DownloadedComicsTableTableManager(
    _$LocalDatabase db,
    $DownloadedComicsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedComicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedComicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedComicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> comicId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String?> titleEnglish = const Value.absent(),
                Value<String?> titleJapanese = const Value.absent(),
                Value<String?> titlePretty = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                Value<String> rootDirectoryPath = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String> downloadedAt = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<int?> numFavorites = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedComicsCompanion(
                comicId: comicId,
                mediaId: mediaId,
                titleEnglish: titleEnglish,
                titleJapanese: titleJapanese,
                titlePretty: titlePretty,
                coverLocalPath: coverLocalPath,
                rootDirectoryPath: rootDirectoryPath,
                pageCount: pageCount,
                downloadedAt: downloadedAt,
                lastReadAt: lastReadAt,
                numFavorites: numFavorites,
                tagsJson: tagsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String comicId,
                required String mediaId,
                Value<String?> titleEnglish = const Value.absent(),
                Value<String?> titleJapanese = const Value.absent(),
                Value<String?> titlePretty = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                required String rootDirectoryPath,
                required int pageCount,
                required String downloadedAt,
                Value<String?> lastReadAt = const Value.absent(),
                Value<int?> numFavorites = const Value.absent(),
                required String tagsJson,
                Value<int> rowid = const Value.absent(),
              }) => DownloadedComicsCompanion.insert(
                comicId: comicId,
                mediaId: mediaId,
                titleEnglish: titleEnglish,
                titleJapanese: titleJapanese,
                titlePretty: titlePretty,
                coverLocalPath: coverLocalPath,
                rootDirectoryPath: rootDirectoryPath,
                pageCount: pageCount,
                downloadedAt: downloadedAt,
                lastReadAt: lastReadAt,
                numFavorites: numFavorites,
                tagsJson: tagsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedComicsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DownloadedComicsTable,
      DownloadedComic,
      $$DownloadedComicsTableFilterComposer,
      $$DownloadedComicsTableOrderingComposer,
      $$DownloadedComicsTableAnnotationComposer,
      $$DownloadedComicsTableCreateCompanionBuilder,
      $$DownloadedComicsTableUpdateCompanionBuilder,
      (
        DownloadedComic,
        BaseReferences<
          _$LocalDatabase,
          $DownloadedComicsTable,
          DownloadedComic
        >,
      ),
      DownloadedComic,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$AppOptionsTableTableManager get appOptions =>
      $$AppOptionsTableTableManager(_db, _db.appOptions);
  $$ComicsTableTableManager get comics =>
      $$ComicsTableTableManager(_db, _db.comics);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$SearchHistoriesTableTableManager get searchHistories =>
      $$SearchHistoriesTableTableManager(_db, _db.searchHistories);
  $$DownloadJobsTableTableManager get downloadJobs =>
      $$DownloadJobsTableTableManager(_db, _db.downloadJobs);
  $$DownloadJobPagesTableTableManager get downloadJobPages =>
      $$DownloadJobPagesTableTableManager(_db, _db.downloadJobPages);
  $$DownloadedComicsTableTableManager get downloadedComics =>
      $$DownloadedComicsTableTableManager(_db, _db.downloadedComics);
}
