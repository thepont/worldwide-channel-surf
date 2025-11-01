import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:worldwide_channel_surf/models/channel.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'channels.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // This is the "Preload" or "Seeding" operation
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE channels(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        targetRegionId TEXT NOT NULL
      )
    ''');
    
    // Seed the database with the default channels
    final batch = db.batch();
    _seedDatabase(batch);
    await batch.commit(noResult: true);
  }
  
  void _seedDatabase(Batch batch) {
    // This is the default data from v9, formatted for the DB
    final defaultChannels = [
      // --- Australia ---
      const Channel(name: "10 Play", url: "https://10play.com.au", targetRegionId: "AU"),
      const Channel(name: "7plus", url: "https://7plus.com.au", targetRegionId: "AU"),
      const Channel(name: "9Now", url: "https://www.9now.com.au", targetRegionId: "AU"),
      const Channel(name: "ABC iview", url: "https://iview.abc.net.au", targetRegionId: "AU"),
      const Channel(name: "SBS On Demand", url: "https://www.sbs.com.au/ondemand", targetRegionId: "AU"),
      // --- France ---
      const Channel(name: "6play", url: "https://www.6play.fr", targetRegionId: "FR"),
      const Channel(name: "Arte", url: "https://www.arte.tv/fr", targetRegionId: "FR"),
      const Channel(name: "France.tv", url: "https://www.france.tv", targetRegionId: "FR"),
      const Channel(name: "TF1+", url: "https://www.tf1plus.fr", targetRegionId: "FR"),
      // --- United Kingdom ---
      const Channel(name: "BBC iPlayer", url: "https://www.bbc.co.uk/iplayer", targetRegionId: "UK"),
      const Channel(name: "Channel 4", url: "https://www.channel4.com", targetRegionId: "UK"),
      const Channel(name: "ITVX", url: "https://www.itv.com", targetRegionId: "UK"),
      const Channel(name: "My5", url: "https://www.channel5.com", targetRegionId: "UK"),
    ];

    for (final channel in defaultChannels) {
      batch.insert('channels', channel.toMap());
    }
  }

  // --- CRUD Operations ---

  Future<List<Channel>> getChannels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('channels', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Channel.fromMap(maps[i]));
  }
  
  // (We can add insert, update, delete methods here later for extensibility)
}

