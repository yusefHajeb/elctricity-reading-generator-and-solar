import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/generator.dart';
import '../models/solar_system.dart';
import '../models/reading.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'power_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE generators(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE solar_systems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        generator_id INTEGER,
        solar_system_id INTEGER,
        meter_reading REAL NOT NULL,
        diesel_consumption REAL,
        reading_date TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (generator_id) REFERENCES generators (id),
        FOREIGN KEY (solar_system_id) REFERENCES solar_systems (id),
        CHECK ((generator_id IS NOT NULL AND solar_system_id IS NULL) OR 
               (generator_id IS NULL AND solar_system_id IS NOT NULL)),
        UNIQUE(generator_id, reading_date),
        UNIQUE(solar_system_id, reading_date)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reading_date column and unique constraints
      await db.execute('ALTER TABLE readings ADD COLUMN reading_date TEXT');
      await db.execute('UPDATE readings SET reading_date = date(timestamp)');

      // Create temporary table with new schema
      await db.execute('''
        CREATE TABLE readings_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          generator_id INTEGER,
          solar_system_id INTEGER,
          meter_reading REAL NOT NULL,
          diesel_consumption REAL,
          reading_date TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (generator_id) REFERENCES generators (id),
          FOREIGN KEY (solar_system_id) REFERENCES solar_systems (id),
          CHECK ((generator_id IS NOT NULL AND solar_system_id IS NULL) OR 
                 (generator_id IS NULL AND solar_system_id IS NOT NULL)),
          UNIQUE(generator_id, reading_date),
          UNIQUE(solar_system_id, reading_date)
        )
      ''');

      // Copy data to new table
      await db.execute('''
        INSERT INTO readings_new 
        SELECT * FROM readings
      ''');

      // Drop old table and rename new table
      await db.execute('DROP TABLE readings');
      await db.execute('ALTER TABLE readings_new RENAME TO readings');
    }
  }

  // Generator operations
  Future<int> insertGenerator(Generator generator) async {
    final db = await database;
    return await db.insert('generators', generator.toMap());
  }

  Future<List<Generator>> getGenerators() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('generators');
    return List.generate(maps.length, (i) => Generator.fromMap(maps[i]));
  }

  // Solar System operations
  Future<int> insertSolarSystem(SolarSystem solarSystem) async {
    final db = await database;
    return await db.insert('solar_systems', solarSystem.toMap());
  }

  Future<List<SolarSystem>> getSolarSystems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('solar_systems');
    return List.generate(maps.length, (i) => SolarSystem.fromMap(maps[i]));
  }

  // Reading operations
  Future<int> insertReading(Reading reading) async {
    final db = await database;
    try {
      return await db.insert(
        'readings',
        reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('A reading already exists for this date');
      }
      rethrow;
    }
  }

  Future<bool> updateReading(Reading reading) async {
    final db = await database;
    final count = await db.update(
      'readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
    return count > 0;
  }

  Future<bool> deleteReading(int id) async {
    final db = await database;
    final count = await db.delete(
      'readings',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<Reading?> getReadingForDate({
    int? generatorId,
    int? solarSystemId,
    required DateTime date,
  }) async {
    assert((generatorId != null) != (solarSystemId != null),
        'Either generatorId or solarSystemId must be provided, but not both');

    final db = await database;
    final String dateStr = date.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: generatorId != null
          ? 'generator_id = ? AND reading_date = ?'
          : 'solar_system_id = ? AND reading_date = ?',
      whereArgs: [generatorId ?? solarSystemId, dateStr],
    );

    if (maps.isEmpty) return null;
    return Reading.fromMap(maps.first);
  }

  Future<List<Reading>> getReadingsForGenerator(int generatorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'generator_id = ?',
      whereArgs: [generatorId],
      orderBy: 'reading_date DESC',
    );
    return List.generate(maps.length, (i) => Reading.fromMap(maps[i]));
  }

  Future<List<Reading>> getReadingsForSolarSystem(int solarSystemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'solar_system_id = ?',
      whereArgs: [solarSystemId],
      orderBy: 'reading_date DESC',
    );
    return List.generate(maps.length, (i) => Reading.fromMap(maps[i]));
  }

  Future<List<Reading>> getReadingsByDateRange2(
    DateTime start,
    DateTime end, {
    int? generatorId,
    int? solarSystemId,
  }) async {
    final db = await database;

    final results = await db.query(
      'readings',
      where: '''
      reading_date >= ? 
      AND reading_date <= ?
      AND (generator_id = ? OR solar_system_id = ?)
    ''',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
        generatorId,
        solarSystemId,
      ],
      orderBy: 'reading_date ASC', // الترتيب التصاعدي مهم للحساب
    );

    return results.map(Reading.fromMap).toList();
  }

  Future<List<Reading>> getReadingsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? generatorId,
    int? solarSystemId,
  }) async {
    final db = await database;
    String whereClause = 'reading_date BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ];

    if (generatorId != null) {
      whereClause += ' AND generator_id = ?';
      whereArgs.add(generatorId);
    } else if (solarSystemId != null) {
      whereClause += ' AND solar_system_id = ?';
      whereArgs.add(solarSystemId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'reading_date DESC',
    );
    return List.generate(maps.length, (i) => Reading.fromMap(maps[i]));
  }

  /// representing the total consumption for that type for the given date.
  ///
  Future<Map<String, double>> getDailyConsumptionSummary(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'reading_date = ?',
      whereArgs: [dateStr],
    );

    double totalGeneratorConsumption = 0;
    double totalSolarConsumption = 0;

    for (var map in maps) {
      final reading = Reading.fromMap(map);
      if (reading.generatorId != null) {
        totalGeneratorConsumption += reading.meterReading;
      } else if (reading.solarSystemId != null) {
        totalSolarConsumption += reading.meterReading;
      }
    }

    return {
      'generator': totalGeneratorConsumption,
      'solar': totalSolarConsumption,
    };
  }

  Future<double> getAverageDieselConsumption(
    int generatorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final readings = await getReadingsByDateRange(
      startDate,
      endDate,
      generatorId: generatorId,
    );

    if (readings.isEmpty) return 0;

    double totalConsumption = 0;
    for (var reading in readings) {
      if (reading.dieselConsumption != null) {
        totalConsumption += reading.dieselConsumption!;
      }
    }

    final days = endDate.difference(startDate).inDays + 1;
    return totalConsumption / days;
  }

  Future<void> importDatabase(Map<String, dynamic> backupData) async {
    final db = await database;

    // Verify backup version
    final backupVersion = backupData['version'] as int;
    if (backupVersion > 2) {
      // Current database version
      throw Exception('Backup version is newer than current database version');
    }

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('readings');
      await txn.delete('generators');
      await txn.delete('solar_systems');

      // Reset auto-increment counters
      await txn
          .execute('DELETE FROM sqlite_sequence WHERE name=?', ['readings']);
      await txn
          .execute('DELETE FROM sqlite_sequence WHERE name=?', ['generators']);
      await txn.execute(
          'DELETE FROM sqlite_sequence WHERE name=?', ['solar_systems']);

      // Import generators
      final generators = backupData['generators'] as List;
      for (var generator in generators) {
        await txn.insert('generators', Map<String, dynamic>.from(generator));
      }

      // Import solar systems
      final solarSystems = backupData['solar_systems'] as List;
      for (var solarSystem in solarSystems) {
        await txn.insert(
            'solar_systems', Map<String, dynamic>.from(solarSystem));
      }

      // Import readings
      final readings = backupData['readings'] as List;
      for (var reading in readings) {
        await txn.insert('readings', Map<String, dynamic>.from(reading));
      }
    });
  }

  Future<Map<String, dynamic>> exportDatabase() async {
    final db = await database;

    // Get all data from tables
    final List<Map<String, dynamic>> generators = await db.query('generators');
    final List<Map<String, dynamic>> solarSystems =
        await db.query('solar_systems');
    final List<Map<String, dynamic>> readings = await db.query('readings');

    return {
      'generators': generators,
      'solar_systems': solarSystems,
      'readings': readings,
      'backup_date': DateTime.now().toIso8601String(),
      'version': 2, // Current database version
    };
  }

  Future<List<Map<String, dynamic>>> getGeneratorReadingsWithDetails(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final query = '''
    SELECT 
      r.*,
      g.name as generator_name
    FROM 
      readings r
    JOIN 
      generators g ON r.generator_id = g.id
    WHERE 
      r.generator_id IS NOT NULL 
      AND r.reading_date BETWEEN ? AND ?
    ORDER BY 
      r.generator_id, r.reading_date ASC
  ''';

    final result = await db.rawQuery(query, [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getSolarReadingsWithDetails(
      DateTime startDate, DateTime endDate) async {
    final db = await database;

    final query = '''
  SELECT 
    r.*,
    s.name as solar_system_name
  FROM 
    readings r
  JOIN 
    solar_systems s ON r.solar_system_id = s.id
  WHERE 
    r.solar_system_id IS NOT NULL 
    AND r.reading_date BETWEEN ? AND ?
  ORDER BY 
    r.solar_system_id, r.reading_date ASC
''';

    final result = await db.rawQuery(query, [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ]);

    return result;
  }

  Future<List<GeneratorConsumption>> calculateGeneratorsConsumption(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final readings = await getGeneratorReadingsWithDetails(
        startDate.subtract(const Duration(days: 1)), endDate);
    final solarReadings = await getSolarReadingsWithDetails(startDate, endDate);
    final Map<int, List<Map<String, dynamic>>> readingsBySolar = {};
    final Map<int, List<Map<String, dynamic>>> readingsByGenerator = {};
    // double totalSolarConsumption = 0;
    for (final reading in solarReadings) {
      readingsBySolar
          .putIfAbsent(reading['solar_system_id'] as int, () => [])
          .add(reading);
      // totalSolarConsumption += reading['meter_reading'] as double;
    }
    // تجميع القراءات حسب المولد
    for (final reading in readings) {
      final generatorId = reading['generator_id'] as int;
      readingsByGenerator.putIfAbsent(generatorId, () => []).add(reading);
    }

    final List<GeneratorConsumption> result = [];

    for (final generatorId in readingsByGenerator.keys) {
      final generatorReadings = readingsByGenerator[generatorId]!;
      String generatorName = generatorReadings.first['generator_name'];

      // الحصول على أول قراءة في الفترة
      final firstReading = generatorReadings.first;

      // الحصول على آخر قراءة في الفترة
      final lastReading = generatorReadings.last;

      // حساب الفرق في عداد الكهرباء
      final meterDifference =
          lastReading['meter_reading'] - firstReading['meter_reading'];

      // حساب مجموع استهلاك الديزل
      double dieselTotal = 0;
      for (final reading in generatorReadings) {
        if (reading['diesel_consumption'] != null) {
          dieselTotal += reading['diesel_consumption'] as double;
        }
      }

      // حساب الكفاءة إذا كان هناك استهلاك ديزل
      double efficiency = dieselTotal > 0 ? meterDifference / dieselTotal : 0;

      result.add(GeneratorConsumption(
        generatorId: generatorId,
        generatorName: generatorName,
        startReading: firstReading['meter_reading'],
        endReading: lastReading['meter_reading'],
        totalConsumption: meterDifference,
        totalDiesel: dieselTotal,
        efficiency: efficiency,
        readingsCount: generatorReadings.length,
      ));
    }

    return result;
  }
}

class GeneratorConsumption {
  final int generatorId;
  final String generatorName;
  final double startReading;
  final double endReading;
  final double totalConsumption;
  final double totalDiesel;
  final double efficiency;
  final int readingsCount;

  GeneratorConsumption({
    required this.generatorId,
    required this.generatorName,
    required this.startReading,
    required this.endReading,
    required this.totalConsumption,
    required this.totalDiesel,
    required this.efficiency,
    required this.readingsCount,
  });
}
