import 'package:elctricity_info/core/date_extensiton.dart';
import 'package:elctricity_info/models/base_consumption.dart';
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

  Future<bool> deleteGenerator(int id) async {
    final db = await database;
    // Delete all readings for this generator first
    await db.delete('readings', where: 'generator_id = ?', whereArgs: [id]);
    // Then delete the generator
    final count =
        await db.delete('generators', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }

  Future<bool> updateGenerator(Generator generator) async {
    final db = await database;
    final count = await db.update(
      'generators',
      generator.toMap(),
      where: 'id = ?',
      whereArgs: [generator.id],
    );
    return count > 0;
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

  Future<bool> deleteSolarSystem(int id) async {
    final db = await database;
    // Delete all readings for this solar system first
    await db.delete('readings', where: 'solar_system_id = ?', whereArgs: [id]);
    // Then delete the solar system
    final count =
        await db.delete('solar_systems', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }

  Future<bool> updateSolarSystem(SolarSystem solarSystem) async {
    final db = await database;
    final count = await db.update(
      'solar_systems',
      solarSystem.toMap(),
      where: 'id = ?',
      whereArgs: [solarSystem.id],
    );
    return count > 0;
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

  Future<Reading?> getPreviousReadingBeforeDate({
    required DateTime date,
    int? generatorId,
    int? solarSystemId,
  }) async {
    final db = await database;

    // بناء جملة WHERE بناءً على المدخلات
    String whereClause = 'reading_date < ?';
    List<dynamic> whereArgs = [date.toIso8601String().split('T')[0]];

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
      orderBy: 'reading_date DESC', // نرتب من الأحدث إلى الأقدم
      limit: 1, // نأخذ فقط أحدث قراءة قبل التاريخ المحدد
    );

    if (maps.isEmpty) {
      return null;
    }

    return Reading.fromMap(maps.first);
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

  Future<List<Map<String, dynamic>>>
      getLastReadingsForAllGeneratorsBeforeDateV2({
    required DateTime targetDate,
  }) async {
    final db = await database;

    final query = '''
    WITH last_readings AS (
      SELECT 
        r.*,
        g.name as generator_name,
        ROW_NUMBER() OVER (PARTITION BY r.generator_id ORDER BY r.reading_date DESC) as rn
      FROM 
        readings r
      JOIN 
        generators g ON r.generator_id = g.id
      WHERE 
        r.reading_date < date(?)
    )
    SELECT * FROM last_readings WHERE rn = 1
  ''';

    final result = await db.rawQuery(query, [targetDate.toIso8601String()]);
    return result;
  }

  Future<List<BaseConsumption>> calculateGeneratorsConsumption(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // جلب قراءة اليوم السابق (لحساب الفرق فقط)
    final previousDayReading =
        await getLastReadingsForAllGeneratorsBeforeDateV2(
      targetDate: startDate,
    );

    // جلب قراءات الفترة المطلوبة
    final periodReadings =
        await getGeneratorReadingsWithDetails(startDate, endDate);

    final Map<int, List<Map<String, dynamic>>> readingsByGenerator = {};
    final solarReadings = await getSolarReadingsWithDetails(startDate, endDate);
    final Map<int, List<Map<String, dynamic>>> readingsBySolar = {};
    double totalSolarConsumption = 0;

    // معالجة قراءات الطاقة الشمسية (كما هي)
    for (final reading in solarReadings) {
      readingsBySolar
          .putIfAbsent(reading['solar_system_id'] as int, () => [])
          .add(reading);
      totalSolarConsumption += reading['meter_reading'] as double;
    }

    // تجميع قراءات المولدات
    for (final reading in periodReadings) {
      final generatorId = reading['generator_id'] as int;
      readingsByGenerator.putIfAbsent(generatorId, () => []).add(reading);
    }

    // إضافة قراءة اليوم السابق إذا وجدت
    for (final reading in previousDayReading) {
      final generatorId = reading['generator_id'] as int;
      if (readingsByGenerator.containsKey(generatorId)) {
        readingsByGenerator[generatorId]!.insert(0, reading);
      }
    }

    final List<BaseConsumption> result = [];

    // معالجة الطاقة الشمسية
    for (final solarId in readingsBySolar.keys) {
      final solarReadings = readingsBySolar[solarId]!;
      String solarSystemName = solarReadings.first['solar_system_name'];
      double totalConsumption = 0;

      for (final reading in solarReadings) {
        totalConsumption += reading['meter_reading'] as double;
      }

      result.add(SolarConsumption(
        solarSystemId: solarId,
        solarSystemName: solarSystemName,
        startReading: totalConsumption,
        endReading: totalConsumption,
        totalConsumption: totalConsumption,
        readingCount: solarReadings.length,
      ));
    }

    // معالجة المولدات
    for (final generatorId in readingsByGenerator.keys) {
      final generatorReadings = readingsByGenerator[generatorId]!;
      String generatorName = generatorReadings.first['generator_name'];

      // نستخدم أول قراءة في الفترة (وليس القراءة السابقة) لحساب الديزل
      final firstPeriodReading = generatorReadings.firstWhere(
        (r) => DateTime.parse(r['reading_date']).isAtLeast(startDate),
        orElse: () => generatorReadings.first,
      );

      final lastReading = generatorReadings.last;

      // حساب الفرق في عداد الكهرباء (بين أول وآخر قراءة)
      final meterDifference = lastReading['meter_reading'] -
          generatorReadings.first['meter_reading'];

      // حساب استهلاك الديزل (فقط للقراءات ضمن الفترة المطلوبة)
      double dieselTotal = 0;
      for (final reading in generatorReadings) {
        final readingDate = DateTime.parse(reading['reading_date']);
        if (readingDate.isAtLeast(startDate) &&
            reading['diesel_consumption'] != null) {
          dieselTotal += reading['diesel_consumption'] as double;
        }
      }

      double efficiency = dieselTotal > 0 ? meterDifference / dieselTotal : 0;

      result.add(GeneratorConsumption(
        generatorId: generatorId,
        generatorName: generatorName,
        startReading: generatorReadings.first['meter_reading'],
        endReading: lastReading['meter_reading'],
        totalConsumption: meterDifference,
        totalDiesel: dieselTotal,
        efficiency: efficiency,
        readingCount: generatorReadings.length,
      ));
    }

    return result;
  }

  Future<List<Reading>> getReadingsWithFallbackStartDate({
    required DateTime startDate,
    required DateTime endDate,
    int? generatorId,
    int? solarSystemId,
    int maxDaysToSearch = 30,
  }) async {
    final db = await database;

    // 1. جلب القراءات الأساسية بين التاريخين
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

    var maps = await db.query(
      'readings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'reading_date ASC', // تغيير إلى ASC لتسهيل إضافة القراءة السابقة
    );

    // 2. التحقق إذا كانت هناك قراءة في تاريخ البداية
    bool hasStartDateReading = maps.isNotEmpty &&
        maps.first['reading_date'] == startDate.toIso8601String().split('T')[0];

    // 3. إذا لم توجد قراءة في تاريخ البداية، نبحث عن القراءة السابقة
    if (!hasStartDateReading) {
      final previousReading = await _findPreviousReading(
        db: db,
        targetDate: startDate,
        generatorId: generatorId,
        solarSystemId: solarSystemId,
        maxDaysToSearch: maxDaysToSearch,
      );

      if (previousReading != null) {
        // إضافة القراءة السابقة في بداية القائمة
        maps.insert(0, previousReading);
      }
    }

    return List.generate(maps.length, (i) => Reading.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>?> _findPreviousReading({
    required Database db,
    required DateTime targetDate,
    int? generatorId,
    int? solarSystemId,
    int maxDaysToSearch = 30,
  }) async {
    // بناء جملة WHERE
    String whereClause = 'reading_date < ?';
    List<dynamic> whereArgs = [targetDate.toIso8601String().split('T')[0]];

    if (generatorId != null) {
      whereClause += ' AND generator_id = ?';
      whereArgs.add(generatorId);
    } else if (solarSystemId != null) {
      whereClause += ' AND solar_system_id = ?';
      whereArgs.add(solarSystemId);
    }

    // 1. محاولة العثور على قراءة في اليوم السابق مباشرة
    var result = await db.query(
      'readings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'reading_date DESC',
      limit: 1,
    );

    // 2. إذا لم يتم العثور، نبحث في الأيام السابقة
    if (result.isEmpty) {
      for (int i = 1; i <= maxDaysToSearch; i++) {
        final searchDate = targetDate.subtract(Duration(days: i));
        whereArgs[0] = searchDate.toIso8601String().split('T')[0];

        result = await db.query(
          'readings',
          where: whereClause,
          whereArgs: whereArgs,
          limit: 1,
        );

        if (result.isNotEmpty) break;
      }
    }

    return result.isEmpty ? null : result.first;
  }
}
