// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetLocalRecordModelCollection on Isar {
  IsarCollection<LocalRecordModel> get localRecordModels => this.collection();
}

const LocalRecordModelSchema = CollectionSchema(
  name: r'LocalRecordModel',
  id: 5685491837939482083,
  properties: {
    r'bodyJson': PropertySchema(id: 0, name: r'bodyJson', type: IsarType.string),
    r'collection': PropertySchema(id: 1, name: r'collection', type: IsarType.string),
    r'createdAt': PropertySchema(id: 2, name: r'createdAt', type: IsarType.dateTime),
    r'createdBy': PropertySchema(id: 3, name: r'createdBy', type: IsarType.string),
    r'deviceId': PropertySchema(id: 4, name: r'deviceId', type: IsarType.string),
    r'isDeleted': PropertySchema(id: 5, name: r'isDeleted', type: IsarType.bool),
    r'key': PropertySchema(id: 6, name: r'key', type: IsarType.string),
    r'recordId': PropertySchema(id: 7, name: r'recordId', type: IsarType.string),
    r'syncStatus': PropertySchema(
      id: 8,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _LocalRecordModelsyncStatusEnumValueMap,
    ),
    r'tenantId': PropertySchema(id: 9, name: r'tenantId', type: IsarType.string),
    r'updatedAt': PropertySchema(id: 10, name: r'updatedAt', type: IsarType.dateTime),
    r'updatedBy': PropertySchema(id: 11, name: r'updatedBy', type: IsarType.string),
    r'version': PropertySchema(id: 12, name: r'version', type: IsarType.long),
  },

  estimateSize: _localRecordModelEstimateSize,
  serialize: _localRecordModelSerialize,
  deserialize: _localRecordModelDeserialize,
  deserializeProp: _localRecordModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [IndexPropertySchema(name: r'key', type: IndexType.hash, caseSensitive: true)],
    ),
    r'tenantId_collection': IndexSchema(
      id: -3590708616786563143,
      name: r'tenantId_collection',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(name: r'tenantId', type: IndexType.hash, caseSensitive: true),
        IndexPropertySchema(name: r'collection', type: IndexType.hash, caseSensitive: true),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _localRecordModelGetId,
  getLinks: _localRecordModelGetLinks,
  attach: _localRecordModelAttach,
  version: '3.4.1',
);

int _localRecordModelEstimateSize(LocalRecordModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bodyJson.length * 3;
  bytesCount += 3 + object.collection.length * 3;
  bytesCount += 3 + object.createdBy.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.recordId.length * 3;
  bytesCount += 3 + object.tenantId.length * 3;
  bytesCount += 3 + object.updatedBy.length * 3;
  return bytesCount;
}

void _localRecordModelSerialize(
  LocalRecordModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bodyJson);
  writer.writeString(offsets[1], object.collection);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.createdBy);
  writer.writeString(offsets[4], object.deviceId);
  writer.writeBool(offsets[5], object.isDeleted);
  writer.writeString(offsets[6], object.key);
  writer.writeString(offsets[7], object.recordId);
  writer.writeByte(offsets[8], object.syncStatus.index);
  writer.writeString(offsets[9], object.tenantId);
  writer.writeDateTime(offsets[10], object.updatedAt);
  writer.writeString(offsets[11], object.updatedBy);
  writer.writeLong(offsets[12], object.version);
}

LocalRecordModel _localRecordModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalRecordModel();
  object.bodyJson = reader.readString(offsets[0]);
  object.collection = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.createdBy = reader.readString(offsets[3]);
  object.deviceId = reader.readString(offsets[4]);
  object.isDeleted = reader.readBool(offsets[5]);
  object.key = reader.readString(offsets[6]);
  object.recordId = reader.readString(offsets[7]);
  object.syncStatus = _LocalRecordModelsyncStatusValueEnumMap[reader.readByteOrNull(offsets[8])] ?? SyncStatus.pending;
  object.tenantId = reader.readString(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  object.updatedBy = reader.readString(offsets[11]);
  object.version = reader.readLong(offsets[12]);
  return object;
}

P _localRecordModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (_LocalRecordModelsyncStatusValueEnumMap[reader.readByteOrNull(offset)] ?? SyncStatus.pending) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _LocalRecordModelsyncStatusEnumValueMap = {'pending': 0, 'synced': 1, 'failed': 2};
const _LocalRecordModelsyncStatusValueEnumMap = {0: SyncStatus.pending, 1: SyncStatus.synced, 2: SyncStatus.failed};

Id _localRecordModelGetId(LocalRecordModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _localRecordModelGetLinks(LocalRecordModel object) {
  return [];
}

void _localRecordModelAttach(IsarCollection<dynamic> col, Id id, LocalRecordModel object) {}

extension LocalRecordModelByIndex on IsarCollection<LocalRecordModel> {
  Future<LocalRecordModel?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  LocalRecordModel? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<LocalRecordModel?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<LocalRecordModel?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(LocalRecordModel object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(LocalRecordModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<LocalRecordModel> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<LocalRecordModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension LocalRecordModelQueryWhereSort on QueryBuilder<LocalRecordModel, LocalRecordModel, QWhere> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalRecordModelQueryWhere on QueryBuilder<LocalRecordModel, LocalRecordModel, QWhereClause> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: isarId, upper: isarId));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false))
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false));
      } else {
        return query
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false))
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false));
      }
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> isarIdGreaterThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: include));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> isarIdLessThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: include));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'key', value: [key]));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false));
      }
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> tenantIdEqualToAnyCollection(String tenantId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'tenantId_collection', value: [tenantId]));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> tenantIdNotEqualToAnyCollection(String tenantId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [],
                upper: [tenantId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [],
                upper: [tenantId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> tenantIdCollectionEqualTo(
    String tenantId,
    String collection,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'tenantId_collection', value: [tenantId, collection]),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterWhereClause> tenantIdEqualToCollectionNotEqualTo(
    String tenantId,
    String collection,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId],
                upper: [tenantId, collection],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId, collection],
                includeLower: false,
                upper: [tenantId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId, collection],
                includeLower: false,
                upper: [tenantId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tenantId_collection',
                lower: [tenantId],
                upper: [tenantId, collection],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalRecordModelQueryFilter on QueryBuilder<LocalRecordModel, LocalRecordModel, QFilterCondition> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'bodyJson', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bodyJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'bodyJson', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bodyJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'bodyJson', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'bodyJson', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'bodyJson', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'bodyJson', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'bodyJson', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> bodyJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'bodyJson', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collection',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'collection', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'collection', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> collectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'collection', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'createdAt', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'createdAt', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'createdBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdBy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'createdBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'createdBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'createdBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'createdBy', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'createdBy', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'createdBy', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'deviceId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'deviceId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'deviceId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'deviceId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'deviceId', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'deviceId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'deviceId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isDeleted', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isarId', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'key', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'key', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'key', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recordId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recordId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'recordId', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'recordId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> recordIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'recordId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'syncStatus', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tenantId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tenantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'tenantId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tenantId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'tenantId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'tenantId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'tenantId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'tenantId', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'tenantId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> tenantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'tenantId', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'updatedAt', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'updatedAt', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'updatedBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedBy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'updatedBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'updatedBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'updatedBy', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'updatedBy', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'updatedBy', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> updatedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'updatedBy', value: ''));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'version', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'version', value: value),
      );
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'version', value: value));
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'version',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LocalRecordModelQueryObject on QueryBuilder<LocalRecordModel, LocalRecordModel, QFilterCondition> {}

extension LocalRecordModelQueryLinks on QueryBuilder<LocalRecordModel, LocalRecordModel, QFilterCondition> {}

extension LocalRecordModelQuerySortBy on QueryBuilder<LocalRecordModel, LocalRecordModel, QSortBy> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByBodyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyJson', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByBodyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyJson', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByTenantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByTenantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LocalRecordModelQuerySortThenBy on QueryBuilder<LocalRecordModel, LocalRecordModel, QSortThenBy> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByBodyJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyJson', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByBodyJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyJson', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByTenantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByTenantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LocalRecordModelQueryWhereDistinct on QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> {
  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByBodyJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByCollection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collection', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByCreatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByDeviceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByRecordId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByTenantId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tenantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByUpdatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRecordModel, LocalRecordModel, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension LocalRecordModelQueryProperty on QueryBuilder<LocalRecordModel, LocalRecordModel, QQueryProperty> {
  QueryBuilder<LocalRecordModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> bodyJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyJson');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> collectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collection');
    });
  }

  QueryBuilder<LocalRecordModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<LocalRecordModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> recordIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordId');
    });
  }

  QueryBuilder<LocalRecordModel, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> tenantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tenantId');
    });
  }

  QueryBuilder<LocalRecordModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<LocalRecordModel, String, QQueryOperations> updatedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedBy');
    });
  }

  QueryBuilder<LocalRecordModel, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetOutboxModelCollection on Isar {
  IsarCollection<OutboxModel> get outboxModels => this.collection();
}

const OutboxModelSchema = CollectionSchema(
  name: r'OutboxModel',
  id: 1700914597035560279,
  properties: {
    r'attempts': PropertySchema(id: 0, name: r'attempts', type: IsarType.long),
    r'collection': PropertySchema(id: 1, name: r'collection', type: IsarType.string),
    r'failed': PropertySchema(id: 2, name: r'failed', type: IsarType.bool),
    r'key': PropertySchema(id: 3, name: r'key', type: IsarType.string),
    r'lastError': PropertySchema(id: 4, name: r'lastError', type: IsarType.string),
    r'nextAttemptAt': PropertySchema(id: 5, name: r'nextAttemptAt', type: IsarType.dateTime),
    r'recordId': PropertySchema(id: 6, name: r'recordId', type: IsarType.string),
    r'seq': PropertySchema(id: 7, name: r'seq', type: IsarType.long),
    r'version': PropertySchema(id: 8, name: r'version', type: IsarType.long),
  },

  estimateSize: _outboxModelEstimateSize,
  serialize: _outboxModelSerialize,
  deserialize: _outboxModelDeserialize,
  deserializeProp: _outboxModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [IndexPropertySchema(name: r'key', type: IndexType.hash, caseSensitive: true)],
    ),
    r'seq': IndexSchema(
      id: -6951239953445392806,
      name: r'seq',
      unique: false,
      replace: false,
      properties: [IndexPropertySchema(name: r'seq', type: IndexType.value, caseSensitive: false)],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _outboxModelGetId,
  getLinks: _outboxModelGetLinks,
  attach: _outboxModelAttach,
  version: '3.4.1',
);

int _outboxModelEstimateSize(OutboxModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.collection.length * 3;
  bytesCount += 3 + object.key.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.recordId.length * 3;
  return bytesCount;
}

void _outboxModelSerialize(OutboxModel object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeString(offsets[1], object.collection);
  writer.writeBool(offsets[2], object.failed);
  writer.writeString(offsets[3], object.key);
  writer.writeString(offsets[4], object.lastError);
  writer.writeDateTime(offsets[5], object.nextAttemptAt);
  writer.writeString(offsets[6], object.recordId);
  writer.writeLong(offsets[7], object.seq);
  writer.writeLong(offsets[8], object.version);
}

OutboxModel _outboxModelDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = OutboxModel();
  object.attempts = reader.readLong(offsets[0]);
  object.collection = reader.readString(offsets[1]);
  object.failed = reader.readBool(offsets[2]);
  object.key = reader.readString(offsets[3]);
  object.lastError = reader.readStringOrNull(offsets[4]);
  object.nextAttemptAt = reader.readDateTimeOrNull(offsets[5]);
  object.recordId = reader.readString(offsets[6]);
  object.seq = reader.readLong(offsets[7]);
  object.version = reader.readLong(offsets[8]);
  return object;
}

P _outboxModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _outboxModelGetId(OutboxModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _outboxModelGetLinks(OutboxModel object) {
  return [];
}

void _outboxModelAttach(IsarCollection<dynamic> col, Id id, OutboxModel object) {}

extension OutboxModelByIndex on IsarCollection<OutboxModel> {
  Future<OutboxModel?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  OutboxModel? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<OutboxModel?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<OutboxModel?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(OutboxModel object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(OutboxModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<OutboxModel> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<OutboxModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension OutboxModelQueryWhereSort on QueryBuilder<OutboxModel, OutboxModel, QWhere> {
  QueryBuilder<OutboxModel, OutboxModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhere> anySeq() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IndexWhereClause.any(indexName: r'seq'));
    });
  }
}

extension OutboxModelQueryWhere on QueryBuilder<OutboxModel, OutboxModel, QWhereClause> {
  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: isarId, upper: isarId));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false))
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false));
      } else {
        return query
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false))
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false));
      }
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: include));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: include));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'key', value: [key]));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false));
      }
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> seqEqualTo(int seq) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'seq', value: [seq]));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> seqNotEqualTo(int seq) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'seq', lower: [], upper: [seq], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'seq', lower: [seq], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'seq', lower: [seq], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'seq', lower: [], upper: [seq], includeUpper: false));
      }
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> seqGreaterThan(int seq, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'seq', lower: [seq], includeLower: include, upper: []),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> seqLessThan(int seq, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'seq', lower: [], upper: [seq], includeUpper: include),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterWhereClause> seqBetween(
    int lowerSeq,
    int upperSeq, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'seq',
          lower: [lowerSeq],
          includeLower: includeLower,
          upper: [upperSeq],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OutboxModelQueryFilter on QueryBuilder<OutboxModel, OutboxModel, QFilterCondition> {
  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'attempts', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> attemptsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'attempts', value: value),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> attemptsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'attempts', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attempts',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collection',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'collection', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'collection', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'collection', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> collectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'collection', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> failedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'failed', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isarId', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'key', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'key', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'key', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'lastError'));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'lastError'));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastError', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'lastError', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastError',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'lastError', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'lastError', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'lastError', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'lastError', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'lastError', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'lastError', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'nextAttemptAt'));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'nextAttemptAt'));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'nextAttemptAt', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'nextAttemptAt', value: value),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'nextAttemptAt', value: value),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> nextAttemptAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextAttemptAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recordId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recordId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'recordId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'recordId', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'recordId', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> recordIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'recordId', value: ''));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> seqEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'seq', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> seqGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'seq', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> seqLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'seq', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> seqBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'seq',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'version', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> versionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'version', value: value),
      );
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> versionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'version', value: value));
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'version',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OutboxModelQueryObject on QueryBuilder<OutboxModel, OutboxModel, QFilterCondition> {}

extension OutboxModelQueryLinks on QueryBuilder<OutboxModel, OutboxModel, QFilterCondition> {}

extension OutboxModelQuerySortBy on QueryBuilder<OutboxModel, OutboxModel, QSortBy> {
  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortBySeq() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seq', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortBySeqDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seq', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension OutboxModelQuerySortThenBy on QueryBuilder<OutboxModel, OutboxModel, QSortThenBy> {
  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenBySeq() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seq', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenBySeqDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seq', Sort.desc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension OutboxModelQueryWhereDistinct on QueryBuilder<OutboxModel, OutboxModel, QDistinct> {
  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByCollection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collection', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failed');
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextAttemptAt');
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByRecordId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctBySeq() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seq');
    });
  }

  QueryBuilder<OutboxModel, OutboxModel, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension OutboxModelQueryProperty on QueryBuilder<OutboxModel, OutboxModel, QQueryProperty> {
  QueryBuilder<OutboxModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OutboxModel, int, QQueryOperations> attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<OutboxModel, String, QQueryOperations> collectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collection');
    });
  }

  QueryBuilder<OutboxModel, bool, QQueryOperations> failedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failed');
    });
  }

  QueryBuilder<OutboxModel, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<OutboxModel, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<OutboxModel, DateTime?, QQueryOperations> nextAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextAttemptAt');
    });
  }

  QueryBuilder<OutboxModel, String, QQueryOperations> recordIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordId');
    });
  }

  QueryBuilder<OutboxModel, int, QQueryOperations> seqProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seq');
    });
  }

  QueryBuilder<OutboxModel, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetSyncCursorModelCollection on Isar {
  IsarCollection<SyncCursorModel> get syncCursorModels => this.collection();
}

const SyncCursorModelSchema = CollectionSchema(
  name: r'SyncCursorModel',
  id: -5633630139823007711,
  properties: {
    r'cursor': PropertySchema(id: 0, name: r'cursor', type: IsarType.string),
    r'key': PropertySchema(id: 1, name: r'key', type: IsarType.string),
  },

  estimateSize: _syncCursorModelEstimateSize,
  serialize: _syncCursorModelSerialize,
  deserialize: _syncCursorModelDeserialize,
  deserializeProp: _syncCursorModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [IndexPropertySchema(name: r'key', type: IndexType.hash, caseSensitive: true)],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _syncCursorModelGetId,
  getLinks: _syncCursorModelGetLinks,
  attach: _syncCursorModelAttach,
  version: '3.4.1',
);

int _syncCursorModelEstimateSize(SyncCursorModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  {
    final value = object.cursor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.key.length * 3;
  return bytesCount;
}

void _syncCursorModelSerialize(
  SyncCursorModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cursor);
  writer.writeString(offsets[1], object.key);
}

SyncCursorModel _syncCursorModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncCursorModel();
  object.cursor = reader.readStringOrNull(offsets[0]);
  object.key = reader.readString(offsets[1]);
  return object;
}

P _syncCursorModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncCursorModelGetId(SyncCursorModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _syncCursorModelGetLinks(SyncCursorModel object) {
  return [];
}

void _syncCursorModelAttach(IsarCollection<dynamic> col, Id id, SyncCursorModel object) {}

extension SyncCursorModelByIndex on IsarCollection<SyncCursorModel> {
  Future<SyncCursorModel?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  SyncCursorModel? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<SyncCursorModel?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<SyncCursorModel?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(SyncCursorModel object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(SyncCursorModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<SyncCursorModel> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<SyncCursorModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension SyncCursorModelQueryWhereSort on QueryBuilder<SyncCursorModel, SyncCursorModel, QWhere> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncCursorModelQueryWhere on QueryBuilder<SyncCursorModel, SyncCursorModel, QWhereClause> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: isarId, upper: isarId));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false))
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false));
      } else {
        return query
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false))
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false));
      }
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> isarIdGreaterThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: include));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: include));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'key', value: [key]));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterWhereClause> keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [key], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'key', lower: [], upper: [key], includeUpper: false));
      }
    });
  }
}

extension SyncCursorModelQueryFilter on QueryBuilder<SyncCursorModel, SyncCursorModel, QFilterCondition> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'cursor'));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'cursor'));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cursor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'cursor', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'cursor', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'cursor', value: ''));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> cursorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'cursor', value: ''));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isarId', value: value));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(property: r'key', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(property: r'key', wildcard: pattern, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'key', value: ''));
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'key', value: ''));
    });
  }
}

extension SyncCursorModelQueryObject on QueryBuilder<SyncCursorModel, SyncCursorModel, QFilterCondition> {}

extension SyncCursorModelQueryLinks on QueryBuilder<SyncCursorModel, SyncCursorModel, QFilterCondition> {}

extension SyncCursorModelQuerySortBy on QueryBuilder<SyncCursorModel, SyncCursorModel, QSortBy> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> sortByCursor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.asc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> sortByCursorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.desc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }
}

extension SyncCursorModelQuerySortThenBy on QueryBuilder<SyncCursorModel, SyncCursorModel, QSortThenBy> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByCursor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.asc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByCursorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.desc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }
}

extension SyncCursorModelQueryWhereDistinct on QueryBuilder<SyncCursorModel, SyncCursorModel, QDistinct> {
  QueryBuilder<SyncCursorModel, SyncCursorModel, QDistinct> distinctByCursor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cursor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncCursorModel, SyncCursorModel, QDistinct> distinctByKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }
}

extension SyncCursorModelQueryProperty on QueryBuilder<SyncCursorModel, SyncCursorModel, QQueryProperty> {
  QueryBuilder<SyncCursorModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SyncCursorModel, String?, QQueryOperations> cursorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cursor');
    });
  }

  QueryBuilder<SyncCursorModel, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }
}
