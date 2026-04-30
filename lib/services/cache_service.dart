import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/departure.dart';

class CacheService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'transit_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE departures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            station TEXT,
            destination TEXT,
            time TEXT,
            delay TEXT,
            track TEXT,
            fetched_at INTEGER
          )
        ''');
      },
    );
  }

  Future<void> cacheDepartures(String station, List<Departure> departures) async {
    final db = await database;
    await db.delete('departures', where: 'station = ?', whereArgs: [station]);
    for (final d in departures) {
      await db.insert('departures', {
        'station': station,
        'destination': d.station,
        'time': d.time,
        'delay': d.delay,
        'track': d.track,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<List<Departure>?> getCached(String station) async {
    final db = await database;
    final tenMinutesAgo = DateTime.now()
        .subtract(const Duration(minutes: 10))
        .millisecondsSinceEpoch;

    final rows = await db.query(
      'departures',
      where: 'station = ? AND fetched_at > ?',
      whereArgs: [station, tenMinutesAgo],
    );

    if (rows.isEmpty) return null;

    return rows.map((r) => Departure(
      station: r['destination'] as String,
      time: r['time'] as String,
      delay: r['delay'] as String,
      track: r['track'] as String,
    )).toList();
  }
}