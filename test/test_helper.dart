import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Initialize database factory for tests
void setupDatabaseFactory() {
  sqfliteFfiInit();
  sqflite.databaseFactory = databaseFactoryFfi;
}

