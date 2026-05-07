import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get localId => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get accountId => text().nullable()();
  TextColumn get fromAccountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get tagJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Categories extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Budgets extends Table {
  TextColumn get localId => text()();
  TextColumn get monthKey => text()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amountLimit => integer()();
  BoolColumn get alert50Enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get alert80Enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get alert100Enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class RecurringExpenses extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  IntColumn get dayOfMonth => integer()();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get lastCreatedMonthKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Accounts extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  TextColumn get weekStart => text().withDefault(const Constant('monday'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  IntColumn get defaultCategorySeedVersion =>
      integer().withDefault(const Constant(0))();
  BoolColumn get appLockEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get exportIncludeDeleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get pinCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BackupMetadata extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  DateTimeColumn get lastRestoreAt => dateTime().nullable()();
  IntColumn get lastBackupVersion => integer().nullable()();
  IntColumn get lastSchemaVersion => integer().nullable()();
  TextColumn get lastBackupFileName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OcrDrafts extends Table {
  TextColumn get localId => text()();
  TextColumn get sourceImagePath => text().nullable()();
  TextColumn get ocrRawText => text().nullable()();
  RealColumn get ocrConfidence => real().nullable()();
  TextColumn get ocrStatus => text()();
  TextColumn get parsedStoreName => text().nullable()();
  IntColumn get parsedTotalAmount => integer().nullable()();
  DateTimeColumn get parsedTransactionDate => dateTime().nullable()();
  TextColumn get parsedCategoryGuess => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}
