import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reading.dart';
import '../service/database_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _startDate;
  DateTime? _endDate;
  // List<Reading>? _readings;
  bool _isLoading = false;
  bool _includeGenerators = true;
  bool _includeSolar = true;
  String _exportFormat = 'excel'; // 'excel' or 'csv'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصدير البيانات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر التواريخ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _selectDate(isStart: true),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_startDate == null
                                ? 'تاريخ البداية'
                                : DateFormat('dd/MM/yyyy').format(_startDate!)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _selectDate(isStart: false),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_endDate == null
                                ? 'تاريخ النهاية'
                                : DateFormat('dd/MM/yyyy').format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختر تنسيق التصدير',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text('Excel'),
                            value: 'excel',
                            groupValue: _exportFormat,
                            onChanged: (value) {
                              setState(() {
                                _exportFormat = value.toString();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text('CSV'),
                            value: 'csv',
                            groupValue: _exportFormat,
                            onChanged: (value) {
                              setState(() {
                                _exportFormat = value.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'البيانات المطلوب ادراجها',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    CheckboxListTile(
                      title: const Text('توليد القراءة'),
                      value: _includeGenerators,
                      onChanged: (value) {
                        setState(() {
                          _includeGenerators = value ?? true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('قراءة المنظومة الشمسية'),
                      value: _includeSolar,
                      onChanged: (value) {
                        setState(() {
                          _includeSolar = value ?? true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_startDate != null &&
                                _endDate != null &&
                                (_includeGenerators || _includeSolar))
                            ? _exportData
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _exportData() async {
    if (_startDate == null || _endDate == null) return;
    if (!_includeGenerators && !_includeSolar) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final readings = await _databaseService.getReadingsByDateRange(
        _startDate!,
        _endDate!,
      );

      // Filter readings based on selection
      final filteredReadings = readings.where((reading) {
        if (reading.generatorId != null && _includeGenerators) return true;
        if (reading.solarSystemId != null && _includeSolar) return true;
        return false;
      }).toList();

      // Group readings by date
      final Map<String, List<Reading>> readingsByDate = {};
      for (var reading in filteredReadings) {
        final dateStr = DateFormat('yyyy-MM-dd').format(reading.readingDate);
        readingsByDate.putIfAbsent(dateStr, () => []).add(reading);
      }

      if (_exportFormat == 'excel') {
        await _exportToExcel(readingsByDate);
      } else {
        await _exportToCSV(readingsByDate);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطاء في تصدير البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToExcel(Map<String, List<Reading>> readingsByDate) async {
    final excel = Excel.createExcel();
    final sheet = excel['Readings'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Source ID'),
      TextCellValue('Total Readings'),
      TextCellValue('Min Reading'),
      TextCellValue('Max Reading'),
      TextCellValue('Avg Reading'),
      TextCellValue('Total Diesel Consumption'),
    ]);

    // Add data rows
    for (var date in readingsByDate.keys) {
      final readings = readingsByDate[date]!;
      final generators = readings.where((r) => r.generatorId != null).toList();
      final solar = readings.where((r) => r.solarSystemId != null).toList();

      // Add generator readings
      if (generators.isNotEmpty) {
        _addReadingsToSheet(sheet, date, 'Generator', generators);
      }

      // Add solar readings
      if (solar.isNotEmpty) {
        _addReadingsToSheet(sheet, date, 'Solar', solar);
      }

      // Add empty row between dates
      sheet.appendRow(List<CellValue>.filled(8, TextCellValue('')));
    }

    try {
      // Save and share the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'readings_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);
      await Share.shareXFiles([XFile(file.path)]);
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
      throw Exception('Failed to export data. Please try again later.');
    }
  }

  void _addReadingsToSheet(
      Sheet sheet, String date, String type, List<Reading> readings) {
    final meterReadings = readings.map((r) => r.meterReading).toList();
    final dieselConsumption = readings
        .where((r) => r.dieselConsumption != null)
        .map((r) => r.dieselConsumption!)
        .fold(0.0, (a, b) => a + b);

    sheet.appendRow([
      TextCellValue(date),
      TextCellValue(type),
      TextCellValue((readings.first.generatorId ?? readings.first.solarSystemId)
          .toString()),
      IntCellValue(readings.length),
      DoubleCellValue(meterReadings.reduce((a, b) => a < b ? a : b)),
      DoubleCellValue(meterReadings.reduce((a, b) => a > b ? a : b)),
      DoubleCellValue(meterReadings.reduce((a, b) => a + b) / readings.length),
      type == 'Generator'
          ? DoubleCellValue(dieselConsumption)
          : TextCellValue('N/A'),
    ]);

    // Add individual readings
    for (var reading in readings) {
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(DateFormat('HH:mm').format(reading.timestamp)),
        DoubleCellValue(reading.meterReading),
        reading.dieselConsumption != null
            ? DoubleCellValue(reading.dieselConsumption!)
            : TextCellValue('N/A'),
        TextCellValue(''),
        TextCellValue(''),
      ]);
    }
  }

  Future<void> _exportToCSV(Map<String, List<Reading>> readingsByDate) async {
    final buffer = StringBuffer();

    // Add headers
    buffer.writeln('Date,Type,Source ID,Time,Meter Reading,Diesel Consumption');

    // Add data rows
    for (var date in readingsByDate.keys) {
      final readings = readingsByDate[date]!;

      // Add daily summary
      buffer.writeln('$date Summary:');
      buffer.writeln('Total Readings: ${readings.length}');
      buffer.writeln(
          'Min Reading: ${readings.map((r) => r.meterReading).reduce((a, b) => a < b ? a : b)}');
      buffer.writeln(
          'Max Reading: ${readings.map((r) => r.meterReading).reduce((a, b) => a > b ? a : b)}');
      buffer.writeln(
          'Avg Reading: ${readings.map((r) => r.meterReading).reduce((a, b) => a + b) / readings.length}');

      // Add individual readings
      for (var reading in readings) {
        buffer.writeln('$date,'
            '${reading.generatorId != null ? "Generator" : "Solar"},'
            '${reading.generatorId ?? reading.solarSystemId},'
            '${DateFormat('HH:mm').format(reading.timestamp)},'
            '${reading.meterReading},'
            '${reading.dieselConsumption ?? "N/A"}');
      }
      buffer.writeln(); // Empty line between dates
    }

    try {
      // Save and share the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'readings_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)]);
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
      throw Exception('Failed to export data. Please try again later.');
    }
  }
}
