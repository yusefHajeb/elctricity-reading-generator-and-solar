import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../service/database_service.dart';

class ReportsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _dailyConsumptionData = {};
  List<Map<String, dynamic>> _detailedReadings = [];

  // Getters
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get dailyConsumptionData => _dailyConsumptionData;
  List<Map<String, dynamic>> get detailedReadings => _detailedReadings;

  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchDailyConsumptionData();
    notifyListeners();
  }

  // Fetch daily consumption data
  Future<void> fetchDailyConsumptionData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get basic consumption summary
      final summary =
          await _databaseService.getDailyConsumptionSummary(_selectedDate);

      // Get all generators
      final generators = await _databaseService.getGenerators();

      // Get detailed readings for the selected date
      final List<Map<String, dynamic>> detailedData = [];

      // Process generator readings
      for (var generator in generators) {
        final reading = await _databaseService.getReadingForDate(
          generatorId: generator.id!,
          date: _selectedDate,
        );

        if (reading != null) {
          // Calculate diesel consumption rate
          final dieselRate =
              reading.dieselConsumption != null && reading.meterReading > 0
                  ? reading.dieselConsumption! / reading.meterReading
                  : 0.0;

          detailedData.add({
            'type': 'generator',
            'id': generator.id,
            'name': generator.name,
            'reading': reading.meterReading,
            'dieselConsumption': reading.dieselConsumption,
            'dieselRate': dieselRate,
            'date': DateFormat('dd/MM/yyyy').format(reading.readingDate),
          });
        }
      }

      // Get solar systems (for future expansion)
      final solarSystems = await _databaseService.getSolarSystems();

      // Process solar readings
      for (var solarSystem in solarSystems) {
        final reading = await _databaseService.getReadingForDate(
          solarSystemId: solarSystem.id!,
          date: _selectedDate,
        );

        if (reading != null) {
          detailedData.add({
            'type': 'solar',
            'id': solarSystem.id,
            'name': solarSystem.name,
            'reading': reading.meterReading,
            'date': DateFormat('dd/MM/yyyy').format(reading.readingDate),
          });
        }
      }

      // Update state
      _dailyConsumptionData = {
        'summary': summary,
        'totalGenerator': summary['generator'] ?? 0.0,
        'totalSolar': summary['solar'] ?? 0.0,
        'total': (summary['generator'] ?? 0.0) + (summary['solar'] ?? 0.0),
      };

      _detailedReadings = detailedData;
    } catch (e) {
      print('Error fetching daily consumption data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get readings for date range
  Future<List<Map<String, dynamic>>> getReadingsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final readings = await _databaseService.getReadingsByDateRange(
        startDate,
        endDate,
      );

      // Get all generators and solar systems for reference
      final generators = await _databaseService.getGenerators();
      final solarSystems = await _databaseService.getSolarSystems();
      // final lastReading = await _databaseService.getReadingForDate(
      //   solarSystemId: readings.first.solarSystemId,
      //   generatorId: readings.first.generatorId,
      //   date: startDate.subtract(const Duration(days: 1)),
      // );

      // Create a map for quick lookup
      final generatorMap = {for (var g in generators) g.id: g};
      final solarMap = {for (var s in solarSystems) s.id: s};

      // Process readings with additional information
      return readings.map((reading) {
        if (reading.generatorId != null) {
          final generator = generatorMap[reading.generatorId];
          final dieselRate =
              reading.dieselConsumption != null && reading.meterReading > 0
                  ? reading.meterReading / reading.dieselConsumption!
                  : 0.0;

          return {
            'type': 'generator',
            'id': reading.generatorId,
            'name': generator?.name ?? 'Unknown Generator',
            'reading': reading.meterReading,
            'dieselConsumption': reading.dieselConsumption,
            'dieselRate': dieselRate,
            'date': DateFormat('dd/MM/yyyy').format(reading.readingDate),
            'readingObj': reading,
          };
        } else if (reading.solarSystemId != null) {
          final solarSystem = solarMap[reading.solarSystemId];

          return {
            'type': 'solar',
            'id': reading.solarSystemId,
            'name': solarSystem?.name ?? 'Unknown Solar System',
            'reading': reading.meterReading,
            'date': DateFormat('dd/MM/yyyy').format(reading.readingDate),
            'readingObj': reading,
          };
        }

        // Fallback (should never happen due to database constraints)
        return {
          'type': 'unknown',
          'reading': reading.meterReading,
          'date': DateFormat('dd/MM/yyyy').format(reading.readingDate),
          'readingObj': reading,
        };
      }).toList();
    } catch (e) {
      log('Error fetching readings for date range: $e');
      print('Error fetching readings for date range: $e');
      return [];
    }
  }

  // Initialize provider
  void init() {
    fetchDailyConsumptionData();
  }
}
