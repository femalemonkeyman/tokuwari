// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetSettingsCollection on Isar {
  IsarCollection<int, Settings> get settings => this.collection();
}

const SettingsSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Settings',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'isNsfw',
        type: IsarType.bool,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, Settings>(
    serialize: serializeSettings,
    deserialize: deserializeSettings,
    deserializeProperty: deserializeSettingsProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeSettings(IsarWriter writer, Settings object) {
  IsarCore.writeBool(writer, 1, object.isNsfw);
  return object.id;
}

@isarProtected
Settings deserializeSettings(IsarReader reader) {
  final object = Settings();
  object.isNsfw = IsarCore.readBool(reader, 1);
  return object;
}

@isarProtected
dynamic deserializeSettingsProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readBool(reader, 1);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _SettingsUpdate {
  bool call({
    required int id,
    bool? isNsfw,
  });
}

class _SettingsUpdateImpl implements _SettingsUpdate {
  const _SettingsUpdateImpl(this.collection);

  final IsarCollection<int, Settings> collection;

  @override
  bool call({
    required int id,
    Object? isNsfw = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (isNsfw != ignore) 1: isNsfw as bool?,
        }) >
        0;
  }
}

sealed class _SettingsUpdateAll {
  int call({
    required List<int> id,
    bool? isNsfw,
  });
}

class _SettingsUpdateAllImpl implements _SettingsUpdateAll {
  const _SettingsUpdateAllImpl(this.collection);

  final IsarCollection<int, Settings> collection;

  @override
  int call({
    required List<int> id,
    Object? isNsfw = ignore,
  }) {
    return collection.updateProperties(id, {
      if (isNsfw != ignore) 1: isNsfw as bool?,
    });
  }
}

extension SettingsUpdate on IsarCollection<int, Settings> {
  _SettingsUpdate get update => _SettingsUpdateImpl(this);

  _SettingsUpdateAll get updateAll => _SettingsUpdateAllImpl(this);
}

sealed class _SettingsQueryUpdate {
  int call({
    bool? isNsfw,
  });
}

class _SettingsQueryUpdateImpl implements _SettingsQueryUpdate {
  const _SettingsQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Settings> query;
  final int? limit;

  @override
  int call({
    Object? isNsfw = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (isNsfw != ignore) 1: isNsfw as bool?,
    });
  }
}

extension SettingsQueryUpdate on IsarQuery<Settings> {
  _SettingsQueryUpdate get updateFirst =>
      _SettingsQueryUpdateImpl(this, limit: 1);

  _SettingsQueryUpdate get updateAll => _SettingsQueryUpdateImpl(this);
}

class _SettingsQueryBuilderUpdateImpl implements _SettingsQueryUpdate {
  const _SettingsQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Settings, Settings, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? isNsfw = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (isNsfw != ignore) 1: isNsfw as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension SettingsQueryBuilderUpdate
    on QueryBuilder<Settings, Settings, QOperations> {
  _SettingsQueryUpdate get updateFirst =>
      _SettingsQueryBuilderUpdateImpl(this, limit: 1);

  _SettingsQueryUpdate get updateAll => _SettingsQueryBuilderUpdateImpl(this);
}

extension SettingsQueryFilter
    on QueryBuilder<Settings, Settings, QFilterCondition> {
  QueryBuilder<Settings, Settings, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> isNsfwEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }
}

extension SettingsQueryObject
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQuerySortBy on QueryBuilder<Settings, Settings, QSortBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByIsNsfwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension SettingsQuerySortThenBy
    on QueryBuilder<Settings, Settings, QSortThenBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIsNsfwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension SettingsQueryWhereDistinct
    on QueryBuilder<Settings, Settings, QDistinct> {
  QueryBuilder<Settings, Settings, QAfterDistinct> distinctByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }
}

extension SettingsQueryProperty1
    on QueryBuilder<Settings, Settings, QProperty> {
  QueryBuilder<Settings, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Settings, bool, QAfterProperty> isNsfwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension SettingsQueryProperty2<R>
    on QueryBuilder<Settings, R, QAfterProperty> {
  QueryBuilder<Settings, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Settings, (R, bool), QAfterProperty> isNsfwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension SettingsQueryProperty3<R1, R2>
    on QueryBuilder<Settings, (R1, R2), QAfterProperty> {
  QueryBuilder<Settings, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Settings, (R1, R2, bool), QOperations> isNsfwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}
