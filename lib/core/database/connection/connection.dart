import 'package:drift/drift.dart';
import 'connection_stub.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.html) 'web.dart';

QueryExecutor openConnection() => openDatabaseConnection();
