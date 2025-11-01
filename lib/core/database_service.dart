import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

/// Database service for managing VPN configurations
/// Uses sqflite to store user's VPN configs locally
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vpn_configs.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vpn_configs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        region_id TEXT NOT NULL,
        template_id TEXT NOT NULL,
        server_address TEXT,
        custom_ovpn_content TEXT
      )
    ''');
  }

  // --- CRUD Operations for VPN Configs ---

  /// Get all VPN configurations
  Future<List<VpnConfig>> getVpnConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vpn_configs',
      orderBy: 'name ASC',
    );
    return maps.map((map) => VpnConfig.fromMap(map)).toList();
  }

  /// Get VPN configs by region
  Future<List<VpnConfig>> getVpnConfigsByRegion(String regionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vpn_configs',
      where: 'region_id = ?',
      whereArgs: [regionId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => VpnConfig.fromMap(map)).toList();
  }

  /// Save a VPN configuration (insert or update)
  Future<int> saveVpnConfig(VpnConfig config) async {
    final db = await database;
    if (config.id == null) {
      // Insert new config
      return await db.insert('vpn_configs', config.toMap());
    } else {
      // Update existing config
      return await db.update(
        'vpn_configs',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [config.id],
      );
    }
  }

  /// Delete a VPN configuration
  Future<int> deleteVpnConfig(int id) async {
    final db = await database;
    return await db.delete(
      'vpn_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get a specific VPN config by ID
  Future<VpnConfig?> getVpnConfigById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vpn_configs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VpnConfig.fromMap(maps.first);
  }
}

