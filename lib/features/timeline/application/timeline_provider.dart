import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers/database_providers.dart';

final timelineTransactionsProvider = StreamProvider((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchTimelineTransactions();
});
