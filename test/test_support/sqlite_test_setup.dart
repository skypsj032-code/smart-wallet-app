import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart' as sqlite3_open;

void configureSqliteForTests() {
  sqlite3_open.open.overrideFor(
    sqlite3_open.OperatingSystem.windows,
    _openBundledSqlite,
  );
}

DynamicLibrary _openBundledSqlite() {
  final current = Directory.current.path;
  final candidates = [
    '$current\\build\\windows\\x64\\plugins\\sqlite3_flutter_libs\\Debug\\sqlite3.dll',
    '$current\\build\\windows\\x64\\plugins\\sqlite3_flutter_libs\\Release\\sqlite3.dll',
    '$current\\build\\windows\\x64\\runner\\Debug\\sqlite3.dll',
    '$current\\build\\windows\\x64\\runner\\Release\\sqlite3.dll',
  ];

  for (final path in candidates) {
    if (File(path).existsSync()) {
      return DynamicLibrary.open(path);
    }
  }

  return DynamicLibrary.open('sqlite3.dll');
}
