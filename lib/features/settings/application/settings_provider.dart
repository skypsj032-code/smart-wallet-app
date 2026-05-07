import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

final appSettingsProvider = StreamProvider<AppSetting>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.select(database.appSettings).watchSingle();
});
