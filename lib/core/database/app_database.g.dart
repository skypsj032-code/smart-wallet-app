// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fromAccountIdMeta =
      const VerificationMeta('fromAccountId');
  @override
  late final GeneratedColumn<String> fromAccountId = GeneratedColumn<String>(
      'from_account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toAccountIdMeta =
      const VerificationMeta('toAccountId');
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
      'to_account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _merchantNameMeta =
      const VerificationMeta('merchantName');
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
      'merchant_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagJsonMeta =
      const VerificationMeta('tagJson');
  @override
  late final GeneratedColumn<String> tagJson = GeneratedColumn<String>(
      'tag_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        type,
        amount,
        occurredAt,
        accountId,
        fromAccountId,
        toAccountId,
        categoryId,
        merchantName,
        paymentMethod,
        memo,
        tagJson,
        createdAt,
        lastModifiedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
          _fromAccountIdMeta,
          fromAccountId.isAcceptableOrUnknown(
              data['from_account_id']!, _fromAccountIdMeta));
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
          _toAccountIdMeta,
          toAccountId.isAcceptableOrUnknown(
              data['to_account_id']!, _toAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
          _merchantNameMeta,
          merchantName.isAcceptableOrUnknown(
              data['merchant_name']!, _merchantNameMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('tag_json')) {
      context.handle(_tagJsonMeta,
          tagJson.isAcceptableOrUnknown(data['tag_json']!, _tagJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      fromAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_account_id']),
      toAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      merchantName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant_name']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      tagJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String localId;
  final String type;
  final int amount;
  final DateTime occurredAt;
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? categoryId;
  final String? merchantName;
  final String? paymentMethod;
  final String? memo;
  final String? tagJson;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final DateTime? deletedAt;
  const Transaction(
      {required this.localId,
      required this.type,
      required this.amount,
      required this.occurredAt,
      this.accountId,
      this.fromAccountId,
      this.toAccountId,
      this.categoryId,
      this.merchantName,
      this.paymentMethod,
      this.memo,
      this.tagJson,
      required this.createdAt,
      required this.lastModifiedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<String>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || merchantName != null) {
      map['merchant_name'] = Variable<String>(merchantName);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || tagJson != null) {
      map['tag_json'] = Variable<String>(tagJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      localId: Value(localId),
      type: Value(type),
      amount: Value(amount),
      occurredAt: Value(occurredAt),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      merchantName: merchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantName),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      tagJson: tagJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagJson),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      localId: serializer.fromJson<String>(json['localId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      fromAccountId: serializer.fromJson<String?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      merchantName: serializer.fromJson<String?>(json['merchantName']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      memo: serializer.fromJson<String?>(json['memo']),
      tagJson: serializer.fromJson<String?>(json['tagJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'accountId': serializer.toJson<String?>(accountId),
      'fromAccountId': serializer.toJson<String?>(fromAccountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'merchantName': serializer.toJson<String?>(merchantName),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'memo': serializer.toJson<String?>(memo),
      'tagJson': serializer.toJson<String?>(tagJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Transaction copyWith(
          {String? localId,
          String? type,
          int? amount,
          DateTime? occurredAt,
          Value<String?> accountId = const Value.absent(),
          Value<String?> fromAccountId = const Value.absent(),
          Value<String?> toAccountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          Value<String?> merchantName = const Value.absent(),
          Value<String?> paymentMethod = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          Value<String?> tagJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastModifiedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Transaction(
        localId: localId ?? this.localId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        occurredAt: occurredAt ?? this.occurredAt,
        accountId: accountId.present ? accountId.value : this.accountId,
        fromAccountId:
            fromAccountId.present ? fromAccountId.value : this.fromAccountId,
        toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        merchantName:
            merchantName.present ? merchantName.value : this.merchantName,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        memo: memo.present ? memo.value : this.memo,
        tagJson: tagJson.present ? tagJson.value : this.tagJson,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      localId: data.localId.present ? data.localId.value : this.localId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId:
          data.toAccountId.present ? data.toAccountId.value : this.toAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      memo: data.memo.present ? data.memo.value : this.memo,
      tagJson: data.tagJson.present ? data.tagJson.value : this.tagJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('localId: $localId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('accountId: $accountId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('merchantName: $merchantName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('memo: $memo, ')
          ..write('tagJson: $tagJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      type,
      amount,
      occurredAt,
      accountId,
      fromAccountId,
      toAccountId,
      categoryId,
      merchantName,
      paymentMethod,
      memo,
      tagJson,
      createdAt,
      lastModifiedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.localId == this.localId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.occurredAt == this.occurredAt &&
          other.accountId == this.accountId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.merchantName == this.merchantName &&
          other.paymentMethod == this.paymentMethod &&
          other.memo == this.memo &&
          other.tagJson == this.tagJson &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> localId;
  final Value<String> type;
  final Value<int> amount;
  final Value<DateTime> occurredAt;
  final Value<String?> accountId;
  final Value<String?> fromAccountId;
  final Value<String?> toAccountId;
  final Value<String?> categoryId;
  final Value<String?> merchantName;
  final Value<String?> paymentMethod;
  final Value<String?> memo;
  final Value<String?> tagJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.localId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.memo = const Value.absent(),
    this.tagJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String localId,
    required String type,
    required int amount,
    required DateTime occurredAt,
    this.accountId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.memo = const Value.absent(),
    this.tagJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        type = Value(type),
        amount = Value(amount),
        occurredAt = Value(occurredAt),
        createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<Transaction> custom({
    Expression<String>? localId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<DateTime>? occurredAt,
    Expression<String>? accountId,
    Expression<String>? fromAccountId,
    Expression<String>? toAccountId,
    Expression<String>? categoryId,
    Expression<String>? merchantName,
    Expression<String>? paymentMethod,
    Expression<String>? memo,
    Expression<String>? tagJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (accountId != null) 'account_id': accountId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (merchantName != null) 'merchant_name': merchantName,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (memo != null) 'memo': memo,
      if (tagJson != null) 'tag_json': tagJson,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? localId,
      Value<String>? type,
      Value<int>? amount,
      Value<DateTime>? occurredAt,
      Value<String?>? accountId,
      Value<String?>? fromAccountId,
      Value<String?>? toAccountId,
      Value<String?>? categoryId,
      Value<String?>? merchantName,
      Value<String?>? paymentMethod,
      Value<String?>? memo,
      Value<String?>? tagJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      localId: localId ?? this.localId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      merchantName: merchantName ?? this.merchantName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      memo: memo ?? this.memo,
      tagJson: tagJson ?? this.tagJson,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<String>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (tagJson.present) {
      map['tag_json'] = Variable<String>(tagJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('localId: $localId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('accountId: $accountId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('merchantName: $merchantName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('memo: $memo, ')
          ..write('tagJson: $tagJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        name,
        type,
        iconName,
        colorHex,
        isDefault,
        isActive,
        sortOrder,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String localId;
  final String name;
  final String type;
  final String? iconName;
  final String? colorHex;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const Category(
      {required this.localId,
      required this.name,
      required this.type,
      this.iconName,
      this.colorHex,
      required this.isDefault,
      required this.isActive,
      required this.sortOrder,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      localId: Value(localId),
      name: Value(name),
      type: Value(type),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      localId: serializer.fromJson<String>(json['localId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'iconName': serializer.toJson<String?>(iconName),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  Category copyWith(
          {String? localId,
          String? name,
          String? type,
          Value<String?> iconName = const Value.absent(),
          Value<String?> colorHex = const Value.absent(),
          bool? isDefault,
          bool? isActive,
          int? sortOrder,
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      Category(
        localId: localId ?? this.localId,
        name: name ?? this.name,
        type: type ?? this.type,
        iconName: iconName.present ? iconName.value : this.iconName,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      localId: data.localId.present ? data.localId.value : this.localId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, name, type, iconName, colorHex,
      isDefault, isActive, sortOrder, createdAt, lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.localId == this.localId &&
          other.name == this.name &&
          other.type == this.type &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> localId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> iconName;
  final Value<String?> colorHex;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.localId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String localId,
    required String name,
    required String type,
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<Category> custom({
    Expression<String>? localId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? iconName,
    Expression<String>? colorHex,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? localId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? iconName,
      Value<String?>? colorHex,
      Value<bool>? isDefault,
      Value<bool>? isActive,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      localId: localId ?? this.localId,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthKeyMeta =
      const VerificationMeta('monthKey');
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
      'month_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountLimitMeta =
      const VerificationMeta('amountLimit');
  @override
  late final GeneratedColumn<int> amountLimit = GeneratedColumn<int>(
      'amount_limit', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _alert50EnabledMeta =
      const VerificationMeta('alert50Enabled');
  @override
  late final GeneratedColumn<bool> alert50Enabled = GeneratedColumn<bool>(
      'alert50_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("alert50_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _alert80EnabledMeta =
      const VerificationMeta('alert80Enabled');
  @override
  late final GeneratedColumn<bool> alert80Enabled = GeneratedColumn<bool>(
      'alert80_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("alert80_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _alert100EnabledMeta =
      const VerificationMeta('alert100Enabled');
  @override
  late final GeneratedColumn<bool> alert100Enabled = GeneratedColumn<bool>(
      'alert100_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("alert100_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        monthKey,
        categoryId,
        amountLimit,
        alert50Enabled,
        alert80Enabled,
        alert100Enabled,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(_monthKeyMeta,
          monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta));
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount_limit')) {
      context.handle(
          _amountLimitMeta,
          amountLimit.isAcceptableOrUnknown(
              data['amount_limit']!, _amountLimitMeta));
    } else if (isInserting) {
      context.missing(_amountLimitMeta);
    }
    if (data.containsKey('alert50_enabled')) {
      context.handle(
          _alert50EnabledMeta,
          alert50Enabled.isAcceptableOrUnknown(
              data['alert50_enabled']!, _alert50EnabledMeta));
    }
    if (data.containsKey('alert80_enabled')) {
      context.handle(
          _alert80EnabledMeta,
          alert80Enabled.isAcceptableOrUnknown(
              data['alert80_enabled']!, _alert80EnabledMeta));
    }
    if (data.containsKey('alert100_enabled')) {
      context.handle(
          _alert100EnabledMeta,
          alert100Enabled.isAcceptableOrUnknown(
              data['alert100_enabled']!, _alert100EnabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      monthKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_key'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amountLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_limit'])!,
      alert50Enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}alert50_enabled'])!,
      alert80Enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}alert80_enabled'])!,
      alert100Enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}alert100_enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String localId;
  final String monthKey;
  final String? categoryId;
  final int amountLimit;
  final bool alert50Enabled;
  final bool alert80Enabled;
  final bool alert100Enabled;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const Budget(
      {required this.localId,
      required this.monthKey,
      this.categoryId,
      required this.amountLimit,
      required this.alert50Enabled,
      required this.alert80Enabled,
      required this.alert100Enabled,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['month_key'] = Variable<String>(monthKey);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount_limit'] = Variable<int>(amountLimit);
    map['alert50_enabled'] = Variable<bool>(alert50Enabled);
    map['alert80_enabled'] = Variable<bool>(alert80Enabled);
    map['alert100_enabled'] = Variable<bool>(alert100Enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      localId: Value(localId),
      monthKey: Value(monthKey),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountLimit: Value(amountLimit),
      alert50Enabled: Value(alert50Enabled),
      alert80Enabled: Value(alert80Enabled),
      alert100Enabled: Value(alert100Enabled),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      localId: serializer.fromJson<String>(json['localId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amountLimit: serializer.fromJson<int>(json['amountLimit']),
      alert50Enabled: serializer.fromJson<bool>(json['alert50Enabled']),
      alert80Enabled: serializer.fromJson<bool>(json['alert80Enabled']),
      alert100Enabled: serializer.fromJson<bool>(json['alert100Enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'monthKey': serializer.toJson<String>(monthKey),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amountLimit': serializer.toJson<int>(amountLimit),
      'alert50Enabled': serializer.toJson<bool>(alert50Enabled),
      'alert80Enabled': serializer.toJson<bool>(alert80Enabled),
      'alert100Enabled': serializer.toJson<bool>(alert100Enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  Budget copyWith(
          {String? localId,
          String? monthKey,
          Value<String?> categoryId = const Value.absent(),
          int? amountLimit,
          bool? alert50Enabled,
          bool? alert80Enabled,
          bool? alert100Enabled,
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      Budget(
        localId: localId ?? this.localId,
        monthKey: monthKey ?? this.monthKey,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amountLimit: amountLimit ?? this.amountLimit,
        alert50Enabled: alert50Enabled ?? this.alert50Enabled,
        alert80Enabled: alert80Enabled ?? this.alert80Enabled,
        alert100Enabled: alert100Enabled ?? this.alert100Enabled,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      localId: data.localId.present ? data.localId.value : this.localId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amountLimit:
          data.amountLimit.present ? data.amountLimit.value : this.amountLimit,
      alert50Enabled: data.alert50Enabled.present
          ? data.alert50Enabled.value
          : this.alert50Enabled,
      alert80Enabled: data.alert80Enabled.present
          ? data.alert80Enabled.value
          : this.alert80Enabled,
      alert100Enabled: data.alert100Enabled.present
          ? data.alert100Enabled.value
          : this.alert100Enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('localId: $localId, ')
          ..write('monthKey: $monthKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountLimit: $amountLimit, ')
          ..write('alert50Enabled: $alert50Enabled, ')
          ..write('alert80Enabled: $alert80Enabled, ')
          ..write('alert100Enabled: $alert100Enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      monthKey,
      categoryId,
      amountLimit,
      alert50Enabled,
      alert80Enabled,
      alert100Enabled,
      createdAt,
      lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.localId == this.localId &&
          other.monthKey == this.monthKey &&
          other.categoryId == this.categoryId &&
          other.amountLimit == this.amountLimit &&
          other.alert50Enabled == this.alert50Enabled &&
          other.alert80Enabled == this.alert80Enabled &&
          other.alert100Enabled == this.alert100Enabled &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> localId;
  final Value<String> monthKey;
  final Value<String?> categoryId;
  final Value<int> amountLimit;
  final Value<bool> alert50Enabled;
  final Value<bool> alert80Enabled;
  final Value<bool> alert100Enabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.localId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountLimit = const Value.absent(),
    this.alert50Enabled = const Value.absent(),
    this.alert80Enabled = const Value.absent(),
    this.alert100Enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String localId,
    required String monthKey,
    this.categoryId = const Value.absent(),
    required int amountLimit,
    this.alert50Enabled = const Value.absent(),
    this.alert80Enabled = const Value.absent(),
    this.alert100Enabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        monthKey = Value(monthKey),
        amountLimit = Value(amountLimit),
        createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<Budget> custom({
    Expression<String>? localId,
    Expression<String>? monthKey,
    Expression<String>? categoryId,
    Expression<int>? amountLimit,
    Expression<bool>? alert50Enabled,
    Expression<bool>? alert80Enabled,
    Expression<bool>? alert100Enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (monthKey != null) 'month_key': monthKey,
      if (categoryId != null) 'category_id': categoryId,
      if (amountLimit != null) 'amount_limit': amountLimit,
      if (alert50Enabled != null) 'alert50_enabled': alert50Enabled,
      if (alert80Enabled != null) 'alert80_enabled': alert80Enabled,
      if (alert100Enabled != null) 'alert100_enabled': alert100Enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? localId,
      Value<String>? monthKey,
      Value<String?>? categoryId,
      Value<int>? amountLimit,
      Value<bool>? alert50Enabled,
      Value<bool>? alert80Enabled,
      Value<bool>? alert100Enabled,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      localId: localId ?? this.localId,
      monthKey: monthKey ?? this.monthKey,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      alert50Enabled: alert50Enabled ?? this.alert50Enabled,
      alert80Enabled: alert80Enabled ?? this.alert80Enabled,
      alert100Enabled: alert100Enabled ?? this.alert100Enabled,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountLimit.present) {
      map['amount_limit'] = Variable<int>(amountLimit.value);
    }
    if (alert50Enabled.present) {
      map['alert50_enabled'] = Variable<bool>(alert50Enabled.value);
    }
    if (alert80Enabled.present) {
      map['alert80_enabled'] = Variable<bool>(alert80Enabled.value);
    }
    if (alert100Enabled.present) {
      map['alert100_enabled'] = Variable<bool>(alert100Enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('localId: $localId, ')
          ..write('monthKey: $monthKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountLimit: $amountLimit, ')
          ..write('alert50Enabled: $alert50Enabled, ')
          ..write('alert80Enabled: $alert80Enabled, ')
          ..write('alert100Enabled: $alert100Enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _includeInNetWorthMeta =
      const VerificationMeta('includeInNetWorth');
  @override
  late final GeneratedColumn<bool> includeInNetWorth = GeneratedColumn<bool>(
      'include_in_net_worth', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("include_in_net_worth" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        name,
        type,
        colorHex,
        includeInNetWorth,
        isActive,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('include_in_net_worth')) {
      context.handle(
          _includeInNetWorthMeta,
          includeInNetWorth.isAcceptableOrUnknown(
              data['include_in_net_worth']!, _includeInNetWorthMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      includeInNetWorth: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}include_in_net_worth'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String localId;
  final String name;
  final String type;
  final String? colorHex;
  final bool includeInNetWorth;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const Account(
      {required this.localId,
      required this.name,
      required this.type,
      this.colorHex,
      required this.includeInNetWorth,
      required this.isActive,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['include_in_net_worth'] = Variable<bool>(includeInNetWorth);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      localId: Value(localId),
      name: Value(name),
      type: Value(type),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      includeInNetWorth: Value(includeInNetWorth),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      localId: serializer.fromJson<String>(json['localId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      includeInNetWorth: serializer.fromJson<bool>(json['includeInNetWorth']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'colorHex': serializer.toJson<String?>(colorHex),
      'includeInNetWorth': serializer.toJson<bool>(includeInNetWorth),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  Account copyWith(
          {String? localId,
          String? name,
          String? type,
          Value<String?> colorHex = const Value.absent(),
          bool? includeInNetWorth,
          bool? isActive,
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      Account(
        localId: localId ?? this.localId,
        name: name ?? this.name,
        type: type ?? this.type,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      localId: data.localId.present ? data.localId.value : this.localId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      includeInNetWorth: data.includeInNetWorth.present
          ? data.includeInNetWorth.value
          : this.includeInNetWorth,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('colorHex: $colorHex, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, name, type, colorHex,
      includeInNetWorth, isActive, createdAt, lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.localId == this.localId &&
          other.name == this.name &&
          other.type == this.type &&
          other.colorHex == this.colorHex &&
          other.includeInNetWorth == this.includeInNetWorth &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> localId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> colorHex;
  final Value<bool> includeInNetWorth;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.localId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String localId,
    required String name,
    required String type,
    this.colorHex = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<Account> custom({
    Expression<String>? localId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? colorHex,
    Expression<bool>? includeInNetWorth,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (colorHex != null) 'color_hex': colorHex,
      if (includeInNetWorth != null) 'include_in_net_worth': includeInNetWorth,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? localId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? colorHex,
      Value<bool>? includeInNetWorth,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      localId: localId ?? this.localId,
      name: name ?? this.name,
      type: type ?? this.type,
      colorHex: colorHex ?? this.colorHex,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (includeInNetWorth.present) {
      map['include_in_net_worth'] = Variable<bool>(includeInNetWorth.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('colorHex: $colorHex, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('KRW'));
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
      'week_start', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('monday'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _appLockEnabledMeta =
      const VerificationMeta('appLockEnabled');
  @override
  late final GeneratedColumn<bool> appLockEnabled = GeneratedColumn<bool>(
      'app_lock_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("app_lock_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _biometricEnabledMeta =
      const VerificationMeta('biometricEnabled');
  @override
  late final GeneratedColumn<bool> biometricEnabled = GeneratedColumn<bool>(
      'biometric_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("biometric_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _exportIncludeDeletedMeta =
      const VerificationMeta('exportIncludeDeleted');
  @override
  late final GeneratedColumn<bool> exportIncludeDeleted = GeneratedColumn<bool>(
      'export_include_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("export_include_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pinCodeMeta =
      const VerificationMeta('pinCode');
  @override
  late final GeneratedColumn<String> pinCode = GeneratedColumn<String>(
      'pin_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        currencyCode,
        weekStart,
        themeMode,
        appLockEnabled,
        biometricEnabled,
        exportIncludeDeleted,
        pinCode,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('app_lock_enabled')) {
      context.handle(
          _appLockEnabledMeta,
          appLockEnabled.isAcceptableOrUnknown(
              data['app_lock_enabled']!, _appLockEnabledMeta));
    }
    if (data.containsKey('biometric_enabled')) {
      context.handle(
          _biometricEnabledMeta,
          biometricEnabled.isAcceptableOrUnknown(
              data['biometric_enabled']!, _biometricEnabledMeta));
    }
    if (data.containsKey('export_include_deleted')) {
      context.handle(
          _exportIncludeDeletedMeta,
          exportIncludeDeleted.isAcceptableOrUnknown(
              data['export_include_deleted']!, _exportIncludeDeletedMeta));
    }
    if (data.containsKey('pin_code')) {
      context.handle(_pinCodeMeta,
          pinCode.isAcceptableOrUnknown(data['pin_code']!, _pinCodeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_start'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      appLockEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}app_lock_enabled'])!,
      biometricEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}biometric_enabled'])!,
      exportIncludeDeleted: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}export_include_deleted'])!,
      pinCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_code']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String currencyCode;
  final String weekStart;
  final String themeMode;
  final bool appLockEnabled;
  final bool biometricEnabled;
  final bool exportIncludeDeleted;
  final String? pinCode;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const AppSetting(
      {required this.id,
      required this.currencyCode,
      required this.weekStart,
      required this.themeMode,
      required this.appLockEnabled,
      required this.biometricEnabled,
      required this.exportIncludeDeleted,
      this.pinCode,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['week_start'] = Variable<String>(weekStart);
    map['theme_mode'] = Variable<String>(themeMode);
    map['app_lock_enabled'] = Variable<bool>(appLockEnabled);
    map['biometric_enabled'] = Variable<bool>(biometricEnabled);
    map['export_include_deleted'] = Variable<bool>(exportIncludeDeleted);
    if (!nullToAbsent || pinCode != null) {
      map['pin_code'] = Variable<String>(pinCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      weekStart: Value(weekStart),
      themeMode: Value(themeMode),
      appLockEnabled: Value(appLockEnabled),
      biometricEnabled: Value(biometricEnabled),
      exportIncludeDeleted: Value(exportIncludeDeleted),
      pinCode: pinCode == null && nullToAbsent
          ? const Value.absent()
          : Value(pinCode),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      appLockEnabled: serializer.fromJson<bool>(json['appLockEnabled']),
      biometricEnabled: serializer.fromJson<bool>(json['biometricEnabled']),
      exportIncludeDeleted:
          serializer.fromJson<bool>(json['exportIncludeDeleted']),
      pinCode: serializer.fromJson<String?>(json['pinCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'weekStart': serializer.toJson<String>(weekStart),
      'themeMode': serializer.toJson<String>(themeMode),
      'appLockEnabled': serializer.toJson<bool>(appLockEnabled),
      'biometricEnabled': serializer.toJson<bool>(biometricEnabled),
      'exportIncludeDeleted': serializer.toJson<bool>(exportIncludeDeleted),
      'pinCode': serializer.toJson<String?>(pinCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  AppSetting copyWith(
          {int? id,
          String? currencyCode,
          String? weekStart,
          String? themeMode,
          bool? appLockEnabled,
          bool? biometricEnabled,
          bool? exportIncludeDeleted,
          Value<String?> pinCode = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      AppSetting(
        id: id ?? this.id,
        currencyCode: currencyCode ?? this.currencyCode,
        weekStart: weekStart ?? this.weekStart,
        themeMode: themeMode ?? this.themeMode,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        exportIncludeDeleted: exportIncludeDeleted ?? this.exportIncludeDeleted,
        pinCode: pinCode.present ? pinCode.value : this.pinCode,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      appLockEnabled: data.appLockEnabled.present
          ? data.appLockEnabled.value
          : this.appLockEnabled,
      biometricEnabled: data.biometricEnabled.present
          ? data.biometricEnabled.value
          : this.biometricEnabled,
      exportIncludeDeleted: data.exportIncludeDeleted.present
          ? data.exportIncludeDeleted.value
          : this.exportIncludeDeleted,
      pinCode: data.pinCode.present ? data.pinCode.value : this.pinCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('weekStart: $weekStart, ')
          ..write('themeMode: $themeMode, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('exportIncludeDeleted: $exportIncludeDeleted, ')
          ..write('pinCode: $pinCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      currencyCode,
      weekStart,
      themeMode,
      appLockEnabled,
      biometricEnabled,
      exportIncludeDeleted,
      pinCode,
      createdAt,
      lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.weekStart == this.weekStart &&
          other.themeMode == this.themeMode &&
          other.appLockEnabled == this.appLockEnabled &&
          other.biometricEnabled == this.biometricEnabled &&
          other.exportIncludeDeleted == this.exportIncludeDeleted &&
          other.pinCode == this.pinCode &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> currencyCode;
  final Value<String> weekStart;
  final Value<String> themeMode;
  final Value<bool> appLockEnabled;
  final Value<bool> biometricEnabled;
  final Value<bool> exportIncludeDeleted;
  final Value<String?> pinCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.exportIncludeDeleted = const Value.absent(),
    this.pinCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.exportIncludeDeleted = const Value.absent(),
    this.pinCode = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
  })  : createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? currencyCode,
    Expression<String>? weekStart,
    Expression<String>? themeMode,
    Expression<bool>? appLockEnabled,
    Expression<bool>? biometricEnabled,
    Expression<bool>? exportIncludeDeleted,
    Expression<String>? pinCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (weekStart != null) 'week_start': weekStart,
      if (themeMode != null) 'theme_mode': themeMode,
      if (appLockEnabled != null) 'app_lock_enabled': appLockEnabled,
      if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      if (exportIncludeDeleted != null)
        'export_include_deleted': exportIncludeDeleted,
      if (pinCode != null) 'pin_code': pinCode,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? currencyCode,
      Value<String>? weekStart,
      Value<String>? themeMode,
      Value<bool>? appLockEnabled,
      Value<bool>? biometricEnabled,
      Value<bool>? exportIncludeDeleted,
      Value<String?>? pinCode,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      weekStart: weekStart ?? this.weekStart,
      themeMode: themeMode ?? this.themeMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      exportIncludeDeleted: exportIncludeDeleted ?? this.exportIncludeDeleted,
      pinCode: pinCode ?? this.pinCode,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (appLockEnabled.present) {
      map['app_lock_enabled'] = Variable<bool>(appLockEnabled.value);
    }
    if (biometricEnabled.present) {
      map['biometric_enabled'] = Variable<bool>(biometricEnabled.value);
    }
    if (exportIncludeDeleted.present) {
      map['export_include_deleted'] =
          Variable<bool>(exportIncludeDeleted.value);
    }
    if (pinCode.present) {
      map['pin_code'] = Variable<String>(pinCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('weekStart: $weekStart, ')
          ..write('themeMode: $themeMode, ')
          ..write('appLockEnabled: $appLockEnabled, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('exportIncludeDeleted: $exportIncludeDeleted, ')
          ..write('pinCode: $pinCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }
}

class $BackupMetadataTable extends BackupMetadata
    with TableInfo<$BackupMetadataTable, BackupMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastBackupAtMeta =
      const VerificationMeta('lastBackupAt');
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
      'last_backup_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastRestoreAtMeta =
      const VerificationMeta('lastRestoreAt');
  @override
  late final GeneratedColumn<DateTime> lastRestoreAt =
      GeneratedColumn<DateTime>('last_restore_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastBackupVersionMeta =
      const VerificationMeta('lastBackupVersion');
  @override
  late final GeneratedColumn<int> lastBackupVersion = GeneratedColumn<int>(
      'last_backup_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastSchemaVersionMeta =
      const VerificationMeta('lastSchemaVersion');
  @override
  late final GeneratedColumn<int> lastSchemaVersion = GeneratedColumn<int>(
      'last_schema_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastBackupFileNameMeta =
      const VerificationMeta('lastBackupFileName');
  @override
  late final GeneratedColumn<String> lastBackupFileName =
      GeneratedColumn<String>('last_backup_file_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lastBackupAt,
        lastRestoreAt,
        lastBackupVersion,
        lastSchemaVersion,
        lastBackupFileName,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<BackupMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
          _lastBackupAtMeta,
          lastBackupAt.isAcceptableOrUnknown(
              data['last_backup_at']!, _lastBackupAtMeta));
    }
    if (data.containsKey('last_restore_at')) {
      context.handle(
          _lastRestoreAtMeta,
          lastRestoreAt.isAcceptableOrUnknown(
              data['last_restore_at']!, _lastRestoreAtMeta));
    }
    if (data.containsKey('last_backup_version')) {
      context.handle(
          _lastBackupVersionMeta,
          lastBackupVersion.isAcceptableOrUnknown(
              data['last_backup_version']!, _lastBackupVersionMeta));
    }
    if (data.containsKey('last_schema_version')) {
      context.handle(
          _lastSchemaVersionMeta,
          lastSchemaVersion.isAcceptableOrUnknown(
              data['last_schema_version']!, _lastSchemaVersionMeta));
    }
    if (data.containsKey('last_backup_file_name')) {
      context.handle(
          _lastBackupFileNameMeta,
          lastBackupFileName.isAcceptableOrUnknown(
              data['last_backup_file_name']!, _lastBackupFileNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupMetadataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lastBackupAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_backup_at']),
      lastRestoreAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_restore_at']),
      lastBackupVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_backup_version']),
      lastSchemaVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_schema_version']),
      lastBackupFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_backup_file_name']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $BackupMetadataTable createAlias(String alias) {
    return $BackupMetadataTable(attachedDatabase, alias);
  }
}

class BackupMetadataData extends DataClass
    implements Insertable<BackupMetadataData> {
  final int id;
  final DateTime? lastBackupAt;
  final DateTime? lastRestoreAt;
  final int? lastBackupVersion;
  final int? lastSchemaVersion;
  final String? lastBackupFileName;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const BackupMetadataData(
      {required this.id,
      this.lastBackupAt,
      this.lastRestoreAt,
      this.lastBackupVersion,
      this.lastSchemaVersion,
      this.lastBackupFileName,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    if (!nullToAbsent || lastRestoreAt != null) {
      map['last_restore_at'] = Variable<DateTime>(lastRestoreAt);
    }
    if (!nullToAbsent || lastBackupVersion != null) {
      map['last_backup_version'] = Variable<int>(lastBackupVersion);
    }
    if (!nullToAbsent || lastSchemaVersion != null) {
      map['last_schema_version'] = Variable<int>(lastSchemaVersion);
    }
    if (!nullToAbsent || lastBackupFileName != null) {
      map['last_backup_file_name'] = Variable<String>(lastBackupFileName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  BackupMetadataCompanion toCompanion(bool nullToAbsent) {
    return BackupMetadataCompanion(
      id: Value(id),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      lastRestoreAt: lastRestoreAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRestoreAt),
      lastBackupVersion: lastBackupVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupVersion),
      lastSchemaVersion: lastSchemaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSchemaVersion),
      lastBackupFileName: lastBackupFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupFileName),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory BackupMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupMetadataData(
      id: serializer.fromJson<int>(json['id']),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
      lastRestoreAt: serializer.fromJson<DateTime?>(json['lastRestoreAt']),
      lastBackupVersion: serializer.fromJson<int?>(json['lastBackupVersion']),
      lastSchemaVersion: serializer.fromJson<int?>(json['lastSchemaVersion']),
      lastBackupFileName:
          serializer.fromJson<String?>(json['lastBackupFileName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
      'lastRestoreAt': serializer.toJson<DateTime?>(lastRestoreAt),
      'lastBackupVersion': serializer.toJson<int?>(lastBackupVersion),
      'lastSchemaVersion': serializer.toJson<int?>(lastSchemaVersion),
      'lastBackupFileName': serializer.toJson<String?>(lastBackupFileName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  BackupMetadataData copyWith(
          {int? id,
          Value<DateTime?> lastBackupAt = const Value.absent(),
          Value<DateTime?> lastRestoreAt = const Value.absent(),
          Value<int?> lastBackupVersion = const Value.absent(),
          Value<int?> lastSchemaVersion = const Value.absent(),
          Value<String?> lastBackupFileName = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      BackupMetadataData(
        id: id ?? this.id,
        lastBackupAt:
            lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
        lastRestoreAt:
            lastRestoreAt.present ? lastRestoreAt.value : this.lastRestoreAt,
        lastBackupVersion: lastBackupVersion.present
            ? lastBackupVersion.value
            : this.lastBackupVersion,
        lastSchemaVersion: lastSchemaVersion.present
            ? lastSchemaVersion.value
            : this.lastSchemaVersion,
        lastBackupFileName: lastBackupFileName.present
            ? lastBackupFileName.value
            : this.lastBackupFileName,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  BackupMetadataData copyWithCompanion(BackupMetadataCompanion data) {
    return BackupMetadataData(
      id: data.id.present ? data.id.value : this.id,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      lastRestoreAt: data.lastRestoreAt.present
          ? data.lastRestoreAt.value
          : this.lastRestoreAt,
      lastBackupVersion: data.lastBackupVersion.present
          ? data.lastBackupVersion.value
          : this.lastBackupVersion,
      lastSchemaVersion: data.lastSchemaVersion.present
          ? data.lastSchemaVersion.value
          : this.lastSchemaVersion,
      lastBackupFileName: data.lastBackupFileName.present
          ? data.lastBackupFileName.value
          : this.lastBackupFileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupMetadataData(')
          ..write('id: $id, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('lastRestoreAt: $lastRestoreAt, ')
          ..write('lastBackupVersion: $lastBackupVersion, ')
          ..write('lastSchemaVersion: $lastSchemaVersion, ')
          ..write('lastBackupFileName: $lastBackupFileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lastBackupAt,
      lastRestoreAt,
      lastBackupVersion,
      lastSchemaVersion,
      lastBackupFileName,
      createdAt,
      lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupMetadataData &&
          other.id == this.id &&
          other.lastBackupAt == this.lastBackupAt &&
          other.lastRestoreAt == this.lastRestoreAt &&
          other.lastBackupVersion == this.lastBackupVersion &&
          other.lastSchemaVersion == this.lastSchemaVersion &&
          other.lastBackupFileName == this.lastBackupFileName &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class BackupMetadataCompanion extends UpdateCompanion<BackupMetadataData> {
  final Value<int> id;
  final Value<DateTime?> lastBackupAt;
  final Value<DateTime?> lastRestoreAt;
  final Value<int?> lastBackupVersion;
  final Value<int?> lastSchemaVersion;
  final Value<String?> lastBackupFileName;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  const BackupMetadataCompanion({
    this.id = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.lastRestoreAt = const Value.absent(),
    this.lastBackupVersion = const Value.absent(),
    this.lastSchemaVersion = const Value.absent(),
    this.lastBackupFileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
  });
  BackupMetadataCompanion.insert({
    this.id = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.lastRestoreAt = const Value.absent(),
    this.lastBackupVersion = const Value.absent(),
    this.lastSchemaVersion = const Value.absent(),
    this.lastBackupFileName = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
  })  : createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<BackupMetadataData> custom({
    Expression<int>? id,
    Expression<DateTime>? lastBackupAt,
    Expression<DateTime>? lastRestoreAt,
    Expression<int>? lastBackupVersion,
    Expression<int>? lastSchemaVersion,
    Expression<String>? lastBackupFileName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (lastRestoreAt != null) 'last_restore_at': lastRestoreAt,
      if (lastBackupVersion != null) 'last_backup_version': lastBackupVersion,
      if (lastSchemaVersion != null) 'last_schema_version': lastSchemaVersion,
      if (lastBackupFileName != null)
        'last_backup_file_name': lastBackupFileName,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
    });
  }

  BackupMetadataCompanion copyWith(
      {Value<int>? id,
      Value<DateTime?>? lastBackupAt,
      Value<DateTime?>? lastRestoreAt,
      Value<int?>? lastBackupVersion,
      Value<int?>? lastSchemaVersion,
      Value<String?>? lastBackupFileName,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt}) {
    return BackupMetadataCompanion(
      id: id ?? this.id,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      lastRestoreAt: lastRestoreAt ?? this.lastRestoreAt,
      lastBackupVersion: lastBackupVersion ?? this.lastBackupVersion,
      lastSchemaVersion: lastSchemaVersion ?? this.lastSchemaVersion,
      lastBackupFileName: lastBackupFileName ?? this.lastBackupFileName,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    if (lastRestoreAt.present) {
      map['last_restore_at'] = Variable<DateTime>(lastRestoreAt.value);
    }
    if (lastBackupVersion.present) {
      map['last_backup_version'] = Variable<int>(lastBackupVersion.value);
    }
    if (lastSchemaVersion.present) {
      map['last_schema_version'] = Variable<int>(lastSchemaVersion.value);
    }
    if (lastBackupFileName.present) {
      map['last_backup_file_name'] = Variable<String>(lastBackupFileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupMetadataCompanion(')
          ..write('id: $id, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('lastRestoreAt: $lastRestoreAt, ')
          ..write('lastBackupVersion: $lastBackupVersion, ')
          ..write('lastSchemaVersion: $lastSchemaVersion, ')
          ..write('lastBackupFileName: $lastBackupFileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }
}

class $OcrDraftsTable extends OcrDrafts
    with TableInfo<$OcrDraftsTable, OcrDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcrDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceImagePathMeta =
      const VerificationMeta('sourceImagePath');
  @override
  late final GeneratedColumn<String> sourceImagePath = GeneratedColumn<String>(
      'source_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrRawTextMeta =
      const VerificationMeta('ocrRawText');
  @override
  late final GeneratedColumn<String> ocrRawText = GeneratedColumn<String>(
      'ocr_raw_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrConfidenceMeta =
      const VerificationMeta('ocrConfidence');
  @override
  late final GeneratedColumn<double> ocrConfidence = GeneratedColumn<double>(
      'ocr_confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ocrStatusMeta =
      const VerificationMeta('ocrStatus');
  @override
  late final GeneratedColumn<String> ocrStatus = GeneratedColumn<String>(
      'ocr_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parsedStoreNameMeta =
      const VerificationMeta('parsedStoreName');
  @override
  late final GeneratedColumn<String> parsedStoreName = GeneratedColumn<String>(
      'parsed_store_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parsedTotalAmountMeta =
      const VerificationMeta('parsedTotalAmount');
  @override
  late final GeneratedColumn<int> parsedTotalAmount = GeneratedColumn<int>(
      'parsed_total_amount', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parsedTransactionDateMeta =
      const VerificationMeta('parsedTransactionDate');
  @override
  late final GeneratedColumn<DateTime> parsedTransactionDate =
      GeneratedColumn<DateTime>('parsed_transaction_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _parsedCategoryGuessMeta =
      const VerificationMeta('parsedCategoryGuess');
  @override
  late final GeneratedColumn<String> parsedCategoryGuess =
      GeneratedColumn<String>('parsed_category_guess', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>('last_modified_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        sourceImagePath,
        ocrRawText,
        ocrConfidence,
        ocrStatus,
        parsedStoreName,
        parsedTotalAmount,
        parsedTransactionDate,
        parsedCategoryGuess,
        errorMessage,
        createdAt,
        lastModifiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocr_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<OcrDraft> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('source_image_path')) {
      context.handle(
          _sourceImagePathMeta,
          sourceImagePath.isAcceptableOrUnknown(
              data['source_image_path']!, _sourceImagePathMeta));
    }
    if (data.containsKey('ocr_raw_text')) {
      context.handle(
          _ocrRawTextMeta,
          ocrRawText.isAcceptableOrUnknown(
              data['ocr_raw_text']!, _ocrRawTextMeta));
    }
    if (data.containsKey('ocr_confidence')) {
      context.handle(
          _ocrConfidenceMeta,
          ocrConfidence.isAcceptableOrUnknown(
              data['ocr_confidence']!, _ocrConfidenceMeta));
    }
    if (data.containsKey('ocr_status')) {
      context.handle(_ocrStatusMeta,
          ocrStatus.isAcceptableOrUnknown(data['ocr_status']!, _ocrStatusMeta));
    } else if (isInserting) {
      context.missing(_ocrStatusMeta);
    }
    if (data.containsKey('parsed_store_name')) {
      context.handle(
          _parsedStoreNameMeta,
          parsedStoreName.isAcceptableOrUnknown(
              data['parsed_store_name']!, _parsedStoreNameMeta));
    }
    if (data.containsKey('parsed_total_amount')) {
      context.handle(
          _parsedTotalAmountMeta,
          parsedTotalAmount.isAcceptableOrUnknown(
              data['parsed_total_amount']!, _parsedTotalAmountMeta));
    }
    if (data.containsKey('parsed_transaction_date')) {
      context.handle(
          _parsedTransactionDateMeta,
          parsedTransactionDate.isAcceptableOrUnknown(
              data['parsed_transaction_date']!, _parsedTransactionDateMeta));
    }
    if (data.containsKey('parsed_category_guess')) {
      context.handle(
          _parsedCategoryGuessMeta,
          parsedCategoryGuess.isAcceptableOrUnknown(
              data['parsed_category_guess']!, _parsedCategoryGuessMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  OcrDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcrDraft(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      sourceImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_image_path']),
      ocrRawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_raw_text']),
      ocrConfidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ocr_confidence']),
      ocrStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_status'])!,
      parsedStoreName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parsed_store_name']),
      parsedTotalAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}parsed_total_amount']),
      parsedTransactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}parsed_transaction_date']),
      parsedCategoryGuess: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parsed_category_guess']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_at'])!,
    );
  }

  @override
  $OcrDraftsTable createAlias(String alias) {
    return $OcrDraftsTable(attachedDatabase, alias);
  }
}

class OcrDraft extends DataClass implements Insertable<OcrDraft> {
  final String localId;
  final String? sourceImagePath;
  final String? ocrRawText;
  final double? ocrConfidence;
  final String ocrStatus;
  final String? parsedStoreName;
  final int? parsedTotalAmount;
  final DateTime? parsedTransactionDate;
  final String? parsedCategoryGuess;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  const OcrDraft(
      {required this.localId,
      this.sourceImagePath,
      this.ocrRawText,
      this.ocrConfidence,
      required this.ocrStatus,
      this.parsedStoreName,
      this.parsedTotalAmount,
      this.parsedTransactionDate,
      this.parsedCategoryGuess,
      this.errorMessage,
      required this.createdAt,
      required this.lastModifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || sourceImagePath != null) {
      map['source_image_path'] = Variable<String>(sourceImagePath);
    }
    if (!nullToAbsent || ocrRawText != null) {
      map['ocr_raw_text'] = Variable<String>(ocrRawText);
    }
    if (!nullToAbsent || ocrConfidence != null) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence);
    }
    map['ocr_status'] = Variable<String>(ocrStatus);
    if (!nullToAbsent || parsedStoreName != null) {
      map['parsed_store_name'] = Variable<String>(parsedStoreName);
    }
    if (!nullToAbsent || parsedTotalAmount != null) {
      map['parsed_total_amount'] = Variable<int>(parsedTotalAmount);
    }
    if (!nullToAbsent || parsedTransactionDate != null) {
      map['parsed_transaction_date'] =
          Variable<DateTime>(parsedTransactionDate);
    }
    if (!nullToAbsent || parsedCategoryGuess != null) {
      map['parsed_category_guess'] = Variable<String>(parsedCategoryGuess);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    return map;
  }

  OcrDraftsCompanion toCompanion(bool nullToAbsent) {
    return OcrDraftsCompanion(
      localId: Value(localId),
      sourceImagePath: sourceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImagePath),
      ocrRawText: ocrRawText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrRawText),
      ocrConfidence: ocrConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConfidence),
      ocrStatus: Value(ocrStatus),
      parsedStoreName: parsedStoreName == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedStoreName),
      parsedTotalAmount: parsedTotalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedTotalAmount),
      parsedTransactionDate: parsedTransactionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedTransactionDate),
      parsedCategoryGuess: parsedCategoryGuess == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedCategoryGuess),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      lastModifiedAt: Value(lastModifiedAt),
    );
  }

  factory OcrDraft.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcrDraft(
      localId: serializer.fromJson<String>(json['localId']),
      sourceImagePath: serializer.fromJson<String?>(json['sourceImagePath']),
      ocrRawText: serializer.fromJson<String?>(json['ocrRawText']),
      ocrConfidence: serializer.fromJson<double?>(json['ocrConfidence']),
      ocrStatus: serializer.fromJson<String>(json['ocrStatus']),
      parsedStoreName: serializer.fromJson<String?>(json['parsedStoreName']),
      parsedTotalAmount: serializer.fromJson<int?>(json['parsedTotalAmount']),
      parsedTransactionDate:
          serializer.fromJson<DateTime?>(json['parsedTransactionDate']),
      parsedCategoryGuess:
          serializer.fromJson<String?>(json['parsedCategoryGuess']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'sourceImagePath': serializer.toJson<String?>(sourceImagePath),
      'ocrRawText': serializer.toJson<String?>(ocrRawText),
      'ocrConfidence': serializer.toJson<double?>(ocrConfidence),
      'ocrStatus': serializer.toJson<String>(ocrStatus),
      'parsedStoreName': serializer.toJson<String?>(parsedStoreName),
      'parsedTotalAmount': serializer.toJson<int?>(parsedTotalAmount),
      'parsedTransactionDate':
          serializer.toJson<DateTime?>(parsedTransactionDate),
      'parsedCategoryGuess': serializer.toJson<String?>(parsedCategoryGuess),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
    };
  }

  OcrDraft copyWith(
          {String? localId,
          Value<String?> sourceImagePath = const Value.absent(),
          Value<String?> ocrRawText = const Value.absent(),
          Value<double?> ocrConfidence = const Value.absent(),
          String? ocrStatus,
          Value<String?> parsedStoreName = const Value.absent(),
          Value<int?> parsedTotalAmount = const Value.absent(),
          Value<DateTime?> parsedTransactionDate = const Value.absent(),
          Value<String?> parsedCategoryGuess = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastModifiedAt}) =>
      OcrDraft(
        localId: localId ?? this.localId,
        sourceImagePath: sourceImagePath.present
            ? sourceImagePath.value
            : this.sourceImagePath,
        ocrRawText: ocrRawText.present ? ocrRawText.value : this.ocrRawText,
        ocrConfidence:
            ocrConfidence.present ? ocrConfidence.value : this.ocrConfidence,
        ocrStatus: ocrStatus ?? this.ocrStatus,
        parsedStoreName: parsedStoreName.present
            ? parsedStoreName.value
            : this.parsedStoreName,
        parsedTotalAmount: parsedTotalAmount.present
            ? parsedTotalAmount.value
            : this.parsedTotalAmount,
        parsedTransactionDate: parsedTransactionDate.present
            ? parsedTransactionDate.value
            : this.parsedTransactionDate,
        parsedCategoryGuess: parsedCategoryGuess.present
            ? parsedCategoryGuess.value
            : this.parsedCategoryGuess,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      );
  OcrDraft copyWithCompanion(OcrDraftsCompanion data) {
    return OcrDraft(
      localId: data.localId.present ? data.localId.value : this.localId,
      sourceImagePath: data.sourceImagePath.present
          ? data.sourceImagePath.value
          : this.sourceImagePath,
      ocrRawText:
          data.ocrRawText.present ? data.ocrRawText.value : this.ocrRawText,
      ocrConfidence: data.ocrConfidence.present
          ? data.ocrConfidence.value
          : this.ocrConfidence,
      ocrStatus: data.ocrStatus.present ? data.ocrStatus.value : this.ocrStatus,
      parsedStoreName: data.parsedStoreName.present
          ? data.parsedStoreName.value
          : this.parsedStoreName,
      parsedTotalAmount: data.parsedTotalAmount.present
          ? data.parsedTotalAmount.value
          : this.parsedTotalAmount,
      parsedTransactionDate: data.parsedTransactionDate.present
          ? data.parsedTransactionDate.value
          : this.parsedTransactionDate,
      parsedCategoryGuess: data.parsedCategoryGuess.present
          ? data.parsedCategoryGuess.value
          : this.parsedCategoryGuess,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcrDraft(')
          ..write('localId: $localId, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('ocrStatus: $ocrStatus, ')
          ..write('parsedStoreName: $parsedStoreName, ')
          ..write('parsedTotalAmount: $parsedTotalAmount, ')
          ..write('parsedTransactionDate: $parsedTransactionDate, ')
          ..write('parsedCategoryGuess: $parsedCategoryGuess, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      sourceImagePath,
      ocrRawText,
      ocrConfidence,
      ocrStatus,
      parsedStoreName,
      parsedTotalAmount,
      parsedTransactionDate,
      parsedCategoryGuess,
      errorMessage,
      createdAt,
      lastModifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrDraft &&
          other.localId == this.localId &&
          other.sourceImagePath == this.sourceImagePath &&
          other.ocrRawText == this.ocrRawText &&
          other.ocrConfidence == this.ocrConfidence &&
          other.ocrStatus == this.ocrStatus &&
          other.parsedStoreName == this.parsedStoreName &&
          other.parsedTotalAmount == this.parsedTotalAmount &&
          other.parsedTransactionDate == this.parsedTransactionDate &&
          other.parsedCategoryGuess == this.parsedCategoryGuess &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class OcrDraftsCompanion extends UpdateCompanion<OcrDraft> {
  final Value<String> localId;
  final Value<String?> sourceImagePath;
  final Value<String?> ocrRawText;
  final Value<double?> ocrConfidence;
  final Value<String> ocrStatus;
  final Value<String?> parsedStoreName;
  final Value<int?> parsedTotalAmount;
  final Value<DateTime?> parsedTransactionDate;
  final Value<String?> parsedCategoryGuess;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastModifiedAt;
  final Value<int> rowid;
  const OcrDraftsCompanion({
    this.localId = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.ocrRawText = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.ocrStatus = const Value.absent(),
    this.parsedStoreName = const Value.absent(),
    this.parsedTotalAmount = const Value.absent(),
    this.parsedTransactionDate = const Value.absent(),
    this.parsedCategoryGuess = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OcrDraftsCompanion.insert({
    required String localId,
    this.sourceImagePath = const Value.absent(),
    this.ocrRawText = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    required String ocrStatus,
    this.parsedStoreName = const Value.absent(),
    this.parsedTotalAmount = const Value.absent(),
    this.parsedTransactionDate = const Value.absent(),
    this.parsedCategoryGuess = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastModifiedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        ocrStatus = Value(ocrStatus),
        createdAt = Value(createdAt),
        lastModifiedAt = Value(lastModifiedAt);
  static Insertable<OcrDraft> custom({
    Expression<String>? localId,
    Expression<String>? sourceImagePath,
    Expression<String>? ocrRawText,
    Expression<double>? ocrConfidence,
    Expression<String>? ocrStatus,
    Expression<String>? parsedStoreName,
    Expression<int>? parsedTotalAmount,
    Expression<DateTime>? parsedTransactionDate,
    Expression<String>? parsedCategoryGuess,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (sourceImagePath != null) 'source_image_path': sourceImagePath,
      if (ocrRawText != null) 'ocr_raw_text': ocrRawText,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (ocrStatus != null) 'ocr_status': ocrStatus,
      if (parsedStoreName != null) 'parsed_store_name': parsedStoreName,
      if (parsedTotalAmount != null) 'parsed_total_amount': parsedTotalAmount,
      if (parsedTransactionDate != null)
        'parsed_transaction_date': parsedTransactionDate,
      if (parsedCategoryGuess != null)
        'parsed_category_guess': parsedCategoryGuess,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OcrDraftsCompanion copyWith(
      {Value<String>? localId,
      Value<String?>? sourceImagePath,
      Value<String?>? ocrRawText,
      Value<double?>? ocrConfidence,
      Value<String>? ocrStatus,
      Value<String?>? parsedStoreName,
      Value<int?>? parsedTotalAmount,
      Value<DateTime?>? parsedTransactionDate,
      Value<String?>? parsedCategoryGuess,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastModifiedAt,
      Value<int>? rowid}) {
    return OcrDraftsCompanion(
      localId: localId ?? this.localId,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      parsedStoreName: parsedStoreName ?? this.parsedStoreName,
      parsedTotalAmount: parsedTotalAmount ?? this.parsedTotalAmount,
      parsedTransactionDate:
          parsedTransactionDate ?? this.parsedTransactionDate,
      parsedCategoryGuess: parsedCategoryGuess ?? this.parsedCategoryGuess,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (sourceImagePath.present) {
      map['source_image_path'] = Variable<String>(sourceImagePath.value);
    }
    if (ocrRawText.present) {
      map['ocr_raw_text'] = Variable<String>(ocrRawText.value);
    }
    if (ocrConfidence.present) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence.value);
    }
    if (ocrStatus.present) {
      map['ocr_status'] = Variable<String>(ocrStatus.value);
    }
    if (parsedStoreName.present) {
      map['parsed_store_name'] = Variable<String>(parsedStoreName.value);
    }
    if (parsedTotalAmount.present) {
      map['parsed_total_amount'] = Variable<int>(parsedTotalAmount.value);
    }
    if (parsedTransactionDate.present) {
      map['parsed_transaction_date'] =
          Variable<DateTime>(parsedTransactionDate.value);
    }
    if (parsedCategoryGuess.present) {
      map['parsed_category_guess'] =
          Variable<String>(parsedCategoryGuess.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcrDraftsCompanion(')
          ..write('localId: $localId, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('ocrStatus: $ocrStatus, ')
          ..write('parsedStoreName: $parsedStoreName, ')
          ..write('parsedTotalAmount: $parsedTotalAmount, ')
          ..write('parsedTransactionDate: $parsedTransactionDate, ')
          ..write('parsedCategoryGuess: $parsedCategoryGuess, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BackupMetadataTable backupMetadata = $BackupMetadataTable(this);
  late final $OcrDraftsTable ocrDrafts = $OcrDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        transactions,
        categories,
        budgets,
        accounts,
        appSettings,
        backupMetadata,
        ocrDrafts
      ];
}

typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String localId,
  required String type,
  required int amount,
  required DateTime occurredAt,
  Value<String?> accountId,
  Value<String?> fromAccountId,
  Value<String?> toAccountId,
  Value<String?> categoryId,
  Value<String?> merchantName,
  Value<String?> paymentMethod,
  Value<String?> memo,
  Value<String?> tagJson,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> localId,
  Value<String> type,
  Value<int> amount,
  Value<DateTime> occurredAt,
  Value<String?> accountId,
  Value<String?> fromAccountId,
  Value<String?> toAccountId,
  Value<String?> categoryId,
  Value<String?> merchantName,
  Value<String?> paymentMethod,
  Value<String?> memo,
  Value<String?> tagJson,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$TransactionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer(super.$state);
  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get occurredAt => $state.composableBuilder(
      column: $state.table.occurredAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get accountId => $state.composableBuilder(
      column: $state.table.accountId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fromAccountId => $state.composableBuilder(
      column: $state.table.fromAccountId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get toAccountId => $state.composableBuilder(
      column: $state.table.toAccountId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get categoryId => $state.composableBuilder(
      column: $state.table.categoryId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get merchantName => $state.composableBuilder(
      column: $state.table.merchantName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tagJson => $state.composableBuilder(
      column: $state.table.tagJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TransactionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get occurredAt => $state.composableBuilder(
      column: $state.table.occurredAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get accountId => $state.composableBuilder(
      column: $state.table.accountId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fromAccountId => $state.composableBuilder(
      column: $state.table.fromAccountId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get toAccountId => $state.composableBuilder(
      column: $state.table.toAccountId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoryId => $state.composableBuilder(
      column: $state.table.categoryId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get merchantName => $state.composableBuilder(
      column: $state.table.merchantName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tagJson => $state.composableBuilder(
      column: $state.table.tagJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TransactionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TransactionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> fromAccountId = const Value.absent(),
            Value<String?> toAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> merchantName = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> tagJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            localId: localId,
            type: type,
            amount: amount,
            occurredAt: occurredAt,
            accountId: accountId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            merchantName: merchantName,
            paymentMethod: paymentMethod,
            memo: memo,
            tagJson: tagJson,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required String type,
            required int amount,
            required DateTime occurredAt,
            Value<String?> accountId = const Value.absent(),
            Value<String?> fromAccountId = const Value.absent(),
            Value<String?> toAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> merchantName = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> tagJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            localId: localId,
            type: type,
            amount: amount,
            occurredAt: occurredAt,
            accountId: accountId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            merchantName: merchantName,
            paymentMethod: paymentMethod,
            memo: memo,
            tagJson: tagJson,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String localId,
  required String name,
  required String type,
  Value<String?> iconName,
  Value<String?> colorHex,
  Value<bool> isDefault,
  Value<bool> isActive,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> localId,
  Value<String> name,
  Value<String> type,
  Value<String?> iconName,
  Value<String?> colorHex,
  Value<bool> isDefault,
  Value<bool> isActive,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDefault => $state.composableBuilder(
      column: $state.table.isDefault,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDefault => $state.composableBuilder(
      column: $state.table.isDefault,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            localId: localId,
            name: name,
            type: type,
            iconName: iconName,
            colorHex: colorHex,
            isDefault: isDefault,
            isActive: isActive,
            sortOrder: sortOrder,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required String name,
            required String type,
            Value<String?> iconName = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            localId: localId,
            name: name,
            type: type,
            iconName: iconName,
            colorHex: colorHex,
            isDefault: isDefault,
            isActive: isActive,
            sortOrder: sortOrder,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String localId,
  required String monthKey,
  Value<String?> categoryId,
  required int amountLimit,
  Value<bool> alert50Enabled,
  Value<bool> alert80Enabled,
  Value<bool> alert100Enabled,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> localId,
  Value<String> monthKey,
  Value<String?> categoryId,
  Value<int> amountLimit,
  Value<bool> alert50Enabled,
  Value<bool> alert80Enabled,
  Value<bool> alert100Enabled,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer(super.$state);
  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get monthKey => $state.composableBuilder(
      column: $state.table.monthKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get categoryId => $state.composableBuilder(
      column: $state.table.categoryId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get amountLimit => $state.composableBuilder(
      column: $state.table.amountLimit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get alert50Enabled => $state.composableBuilder(
      column: $state.table.alert50Enabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get alert80Enabled => $state.composableBuilder(
      column: $state.table.alert80Enabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get alert100Enabled => $state.composableBuilder(
      column: $state.table.alert100Enabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BudgetsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get monthKey => $state.composableBuilder(
      column: $state.table.monthKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoryId => $state.composableBuilder(
      column: $state.table.categoryId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get amountLimit => $state.composableBuilder(
      column: $state.table.amountLimit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get alert50Enabled => $state.composableBuilder(
      column: $state.table.alert50Enabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get alert80Enabled => $state.composableBuilder(
      column: $state.table.alert80Enabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get alert100Enabled => $state.composableBuilder(
      column: $state.table.alert100Enabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BudgetsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BudgetsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String> monthKey = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> amountLimit = const Value.absent(),
            Value<bool> alert50Enabled = const Value.absent(),
            Value<bool> alert80Enabled = const Value.absent(),
            Value<bool> alert100Enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            localId: localId,
            monthKey: monthKey,
            categoryId: categoryId,
            amountLimit: amountLimit,
            alert50Enabled: alert50Enabled,
            alert80Enabled: alert80Enabled,
            alert100Enabled: alert100Enabled,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required String monthKey,
            Value<String?> categoryId = const Value.absent(),
            required int amountLimit,
            Value<bool> alert50Enabled = const Value.absent(),
            Value<bool> alert80Enabled = const Value.absent(),
            Value<bool> alert100Enabled = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            localId: localId,
            monthKey: monthKey,
            categoryId: categoryId,
            amountLimit: amountLimit,
            alert50Enabled: alert50Enabled,
            alert80Enabled: alert80Enabled,
            alert100Enabled: alert100Enabled,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String localId,
  required String name,
  required String type,
  Value<String?> colorHex,
  Value<bool> includeInNetWorth,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> localId,
  Value<String> name,
  Value<String> type,
  Value<String?> colorHex,
  Value<bool> includeInNetWorth,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer(super.$state);
  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get includeInNetWorth => $state.composableBuilder(
      column: $state.table.includeInNetWorth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AccountsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get includeInNetWorth => $state.composableBuilder(
      column: $state.table.includeInNetWorth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AccountsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AccountsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> includeInNetWorth = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            localId: localId,
            name: name,
            type: type,
            colorHex: colorHex,
            includeInNetWorth: includeInNetWorth,
            isActive: isActive,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required String name,
            required String type,
            Value<String?> colorHex = const Value.absent(),
            Value<bool> includeInNetWorth = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            localId: localId,
            name: name,
            type: type,
            colorHex: colorHex,
            includeInNetWorth: includeInNetWorth,
            isActive: isActive,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> currencyCode,
  Value<String> weekStart,
  Value<String> themeMode,
  Value<bool> appLockEnabled,
  Value<bool> biometricEnabled,
  Value<bool> exportIncludeDeleted,
  Value<String?> pinCode,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> currencyCode,
  Value<String> weekStart,
  Value<String> themeMode,
  Value<bool> appLockEnabled,
  Value<bool> biometricEnabled,
  Value<bool> exportIncludeDeleted,
  Value<String?> pinCode,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
});

class $$AppSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currencyCode => $state.composableBuilder(
      column: $state.table.currencyCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get themeMode => $state.composableBuilder(
      column: $state.table.themeMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get appLockEnabled => $state.composableBuilder(
      column: $state.table.appLockEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get biometricEnabled => $state.composableBuilder(
      column: $state.table.biometricEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get exportIncludeDeleted => $state.composableBuilder(
      column: $state.table.exportIncludeDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pinCode => $state.composableBuilder(
      column: $state.table.pinCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currencyCode => $state.composableBuilder(
      column: $state.table.currencyCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get weekStart => $state.composableBuilder(
      column: $state.table.weekStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get themeMode => $state.composableBuilder(
      column: $state.table.themeMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get appLockEnabled => $state.composableBuilder(
      column: $state.table.appLockEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get biometricEnabled => $state.composableBuilder(
      column: $state.table.biometricEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get exportIncludeDeleted => $state.composableBuilder(
      column: $state.table.exportIncludeDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pinCode => $state.composableBuilder(
      column: $state.table.pinCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AppSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AppSettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<bool> appLockEnabled = const Value.absent(),
            Value<bool> biometricEnabled = const Value.absent(),
            Value<bool> exportIncludeDeleted = const Value.absent(),
            Value<String?> pinCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            currencyCode: currencyCode,
            weekStart: weekStart,
            themeMode: themeMode,
            appLockEnabled: appLockEnabled,
            biometricEnabled: biometricEnabled,
            exportIncludeDeleted: exportIncludeDeleted,
            pinCode: pinCode,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<bool> appLockEnabled = const Value.absent(),
            Value<bool> biometricEnabled = const Value.absent(),
            Value<bool> exportIncludeDeleted = const Value.absent(),
            Value<String?> pinCode = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            currencyCode: currencyCode,
            weekStart: weekStart,
            themeMode: themeMode,
            appLockEnabled: appLockEnabled,
            biometricEnabled: biometricEnabled,
            exportIncludeDeleted: exportIncludeDeleted,
            pinCode: pinCode,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$BackupMetadataTableCreateCompanionBuilder = BackupMetadataCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastBackupAt,
  Value<DateTime?> lastRestoreAt,
  Value<int?> lastBackupVersion,
  Value<int?> lastSchemaVersion,
  Value<String?> lastBackupFileName,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
});
typedef $$BackupMetadataTableUpdateCompanionBuilder = BackupMetadataCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastBackupAt,
  Value<DateTime?> lastRestoreAt,
  Value<int?> lastBackupVersion,
  Value<int?> lastSchemaVersion,
  Value<String?> lastBackupFileName,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
});

class $$BackupMetadataTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BackupMetadataTable> {
  $$BackupMetadataTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastBackupAt => $state.composableBuilder(
      column: $state.table.lastBackupAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastRestoreAt => $state.composableBuilder(
      column: $state.table.lastRestoreAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastBackupVersion => $state.composableBuilder(
      column: $state.table.lastBackupVersion,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastSchemaVersion => $state.composableBuilder(
      column: $state.table.lastSchemaVersion,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastBackupFileName => $state.composableBuilder(
      column: $state.table.lastBackupFileName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BackupMetadataTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BackupMetadataTable> {
  $$BackupMetadataTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastBackupAt => $state.composableBuilder(
      column: $state.table.lastBackupAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastRestoreAt => $state.composableBuilder(
      column: $state.table.lastRestoreAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastBackupVersion => $state.composableBuilder(
      column: $state.table.lastBackupVersion,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastSchemaVersion => $state.composableBuilder(
      column: $state.table.lastSchemaVersion,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastBackupFileName => $state.composableBuilder(
      column: $state.table.lastBackupFileName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$BackupMetadataTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BackupMetadataTable,
    BackupMetadataData,
    $$BackupMetadataTableFilterComposer,
    $$BackupMetadataTableOrderingComposer,
    $$BackupMetadataTableCreateCompanionBuilder,
    $$BackupMetadataTableUpdateCompanionBuilder,
    (
      BackupMetadataData,
      BaseReferences<_$AppDatabase, $BackupMetadataTable, BackupMetadataData>
    ),
    BackupMetadataData,
    PrefetchHooks Function()> {
  $$BackupMetadataTableTableManager(
      _$AppDatabase db, $BackupMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BackupMetadataTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BackupMetadataTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastBackupAt = const Value.absent(),
            Value<DateTime?> lastRestoreAt = const Value.absent(),
            Value<int?> lastBackupVersion = const Value.absent(),
            Value<int?> lastSchemaVersion = const Value.absent(),
            Value<String?> lastBackupFileName = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
          }) =>
              BackupMetadataCompanion(
            id: id,
            lastBackupAt: lastBackupAt,
            lastRestoreAt: lastRestoreAt,
            lastBackupVersion: lastBackupVersion,
            lastSchemaVersion: lastSchemaVersion,
            lastBackupFileName: lastBackupFileName,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastBackupAt = const Value.absent(),
            Value<DateTime?> lastRestoreAt = const Value.absent(),
            Value<int?> lastBackupVersion = const Value.absent(),
            Value<int?> lastSchemaVersion = const Value.absent(),
            Value<String?> lastBackupFileName = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
          }) =>
              BackupMetadataCompanion.insert(
            id: id,
            lastBackupAt: lastBackupAt,
            lastRestoreAt: lastRestoreAt,
            lastBackupVersion: lastBackupVersion,
            lastSchemaVersion: lastSchemaVersion,
            lastBackupFileName: lastBackupFileName,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BackupMetadataTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BackupMetadataTable,
    BackupMetadataData,
    $$BackupMetadataTableFilterComposer,
    $$BackupMetadataTableOrderingComposer,
    $$BackupMetadataTableCreateCompanionBuilder,
    $$BackupMetadataTableUpdateCompanionBuilder,
    (
      BackupMetadataData,
      BaseReferences<_$AppDatabase, $BackupMetadataTable, BackupMetadataData>
    ),
    BackupMetadataData,
    PrefetchHooks Function()>;
typedef $$OcrDraftsTableCreateCompanionBuilder = OcrDraftsCompanion Function({
  required String localId,
  Value<String?> sourceImagePath,
  Value<String?> ocrRawText,
  Value<double?> ocrConfidence,
  required String ocrStatus,
  Value<String?> parsedStoreName,
  Value<int?> parsedTotalAmount,
  Value<DateTime?> parsedTransactionDate,
  Value<String?> parsedCategoryGuess,
  Value<String?> errorMessage,
  required DateTime createdAt,
  required DateTime lastModifiedAt,
  Value<int> rowid,
});
typedef $$OcrDraftsTableUpdateCompanionBuilder = OcrDraftsCompanion Function({
  Value<String> localId,
  Value<String?> sourceImagePath,
  Value<String?> ocrRawText,
  Value<double?> ocrConfidence,
  Value<String> ocrStatus,
  Value<String?> parsedStoreName,
  Value<int?> parsedTotalAmount,
  Value<DateTime?> parsedTransactionDate,
  Value<String?> parsedCategoryGuess,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> lastModifiedAt,
  Value<int> rowid,
});

class $$OcrDraftsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $OcrDraftsTable> {
  $$OcrDraftsTableFilterComposer(super.$state);
  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceImagePath => $state.composableBuilder(
      column: $state.table.sourceImagePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ocrRawText => $state.composableBuilder(
      column: $state.table.ocrRawText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get ocrConfidence => $state.composableBuilder(
      column: $state.table.ocrConfidence,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ocrStatus => $state.composableBuilder(
      column: $state.table.ocrStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get parsedStoreName => $state.composableBuilder(
      column: $state.table.parsedStoreName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get parsedTotalAmount => $state.composableBuilder(
      column: $state.table.parsedTotalAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get parsedTransactionDate => $state.composableBuilder(
      column: $state.table.parsedTransactionDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get parsedCategoryGuess => $state.composableBuilder(
      column: $state.table.parsedCategoryGuess,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$OcrDraftsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $OcrDraftsTable> {
  $$OcrDraftsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceImagePath => $state.composableBuilder(
      column: $state.table.sourceImagePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ocrRawText => $state.composableBuilder(
      column: $state.table.ocrRawText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get ocrConfidence => $state.composableBuilder(
      column: $state.table.ocrConfidence,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ocrStatus => $state.composableBuilder(
      column: $state.table.ocrStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get parsedStoreName => $state.composableBuilder(
      column: $state.table.parsedStoreName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get parsedTotalAmount => $state.composableBuilder(
      column: $state.table.parsedTotalAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get parsedTransactionDate =>
      $state.composableBuilder(
          column: $state.table.parsedTransactionDate,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get parsedCategoryGuess => $state.composableBuilder(
      column: $state.table.parsedCategoryGuess,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$OcrDraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OcrDraftsTable,
    OcrDraft,
    $$OcrDraftsTableFilterComposer,
    $$OcrDraftsTableOrderingComposer,
    $$OcrDraftsTableCreateCompanionBuilder,
    $$OcrDraftsTableUpdateCompanionBuilder,
    (OcrDraft, BaseReferences<_$AppDatabase, $OcrDraftsTable, OcrDraft>),
    OcrDraft,
    PrefetchHooks Function()> {
  $$OcrDraftsTableTableManager(_$AppDatabase db, $OcrDraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$OcrDraftsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$OcrDraftsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> sourceImagePath = const Value.absent(),
            Value<String?> ocrRawText = const Value.absent(),
            Value<double?> ocrConfidence = const Value.absent(),
            Value<String> ocrStatus = const Value.absent(),
            Value<String?> parsedStoreName = const Value.absent(),
            Value<int?> parsedTotalAmount = const Value.absent(),
            Value<DateTime?> parsedTransactionDate = const Value.absent(),
            Value<String?> parsedCategoryGuess = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastModifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OcrDraftsCompanion(
            localId: localId,
            sourceImagePath: sourceImagePath,
            ocrRawText: ocrRawText,
            ocrConfidence: ocrConfidence,
            ocrStatus: ocrStatus,
            parsedStoreName: parsedStoreName,
            parsedTotalAmount: parsedTotalAmount,
            parsedTransactionDate: parsedTransactionDate,
            parsedCategoryGuess: parsedCategoryGuess,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            Value<String?> sourceImagePath = const Value.absent(),
            Value<String?> ocrRawText = const Value.absent(),
            Value<double?> ocrConfidence = const Value.absent(),
            required String ocrStatus,
            Value<String?> parsedStoreName = const Value.absent(),
            Value<int?> parsedTotalAmount = const Value.absent(),
            Value<DateTime?> parsedTransactionDate = const Value.absent(),
            Value<String?> parsedCategoryGuess = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastModifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OcrDraftsCompanion.insert(
            localId: localId,
            sourceImagePath: sourceImagePath,
            ocrRawText: ocrRawText,
            ocrConfidence: ocrConfidence,
            ocrStatus: ocrStatus,
            parsedStoreName: parsedStoreName,
            parsedTotalAmount: parsedTotalAmount,
            parsedTransactionDate: parsedTransactionDate,
            parsedCategoryGuess: parsedCategoryGuess,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OcrDraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OcrDraftsTable,
    OcrDraft,
    $$OcrDraftsTableFilterComposer,
    $$OcrDraftsTableOrderingComposer,
    $$OcrDraftsTableCreateCompanionBuilder,
    $$OcrDraftsTableUpdateCompanionBuilder,
    (OcrDraft, BaseReferences<_$AppDatabase, $OcrDraftsTable, OcrDraft>),
    OcrDraft,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BackupMetadataTableTableManager get backupMetadata =>
      $$BackupMetadataTableTableManager(_db, _db.backupMetadata);
  $$OcrDraftsTableTableManager get ocrDrafts =>
      $$OcrDraftsTableTableManager(_db, _db.ocrDrafts);
}
