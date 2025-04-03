import 'package:elctricity_info/models/solar_system.dart';
import 'package:elctricity_info/widget/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reading.dart';
import '../providers/reports_provider.dart';
import '../service/database_service.dart';
import '../service/pdf_service.dart';

class SolarAnalysisScreen extends StatefulWidget {
  final SolarSystem solar;

  const SolarAnalysisScreen({
    super.key,
    required this.solar,
  });

  @override
  State<SolarAnalysisScreen> createState() => _SolarAnalysisScreenState();
}

class _SolarAnalysisScreenState extends State<SolarAnalysisScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  List<Reading>? _readings;
  List<Map<String, dynamic>>? _detailedReadings;
  Map<String, dynamic> _summary = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.solar.name} تقرير'),
        actions: [
          if (_readings != null && _readings!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'تصدير PDF',
              onPressed: _exportToPdf,
            ),
        ],
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
                      'اختيار التواريخ',
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
                                ? 'تأريخ البداية'
                                : DateFormat('dd/MM/yyyy').format(_startDate!)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _selectDate(isStart: false),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_endDate == null
                                ? 'تأريخ النهاية'
                                : DateFormat('dd/MM/yyyy').format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startDate != null && _endDate != null
                            ? _generateReport
                            : null,
                        icon: const Icon(Icons.assessment),
                        label: const Text('توليد التقرير'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_readings != null && _readings!.isNotEmpty) ...[
              Text(
                'نتائج التقرير',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildReadingsList(),
              ),
            ] else if (_readings != null && _readings!.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد قراءات في هذه الفترة',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        _readings = null;
        _detailedReadings = null;
        _summary = {};
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get readings for this specific generator
      final readings = await _databaseService.getReadingsByDateRange(
        _startDate!.subtract(const Duration(days: 1)),
        _endDate!,
        solarSystemId: widget.solar.id,
      );

      // Get detailed readings using the provider
      final reportsProvider =
          Provider.of<ReportsProvider>(context, listen: false);
      final allDetailedReadings =
          await reportsProvider.getReadingsForDateRange(_startDate!, _endDate!);

      // Filter for only this generator
      final detailedReadings = allDetailedReadings
          .where((reading) =>
              reading['type'] == 'solar' && reading['id'] == widget.solar.id)
          .toList();

      // Calculate summary data
      readings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

      double totalConsumption = 0;
      double totalDiesel = 0;
      List<double> dailyRates = [];
      for (int i = 0; i < readings.length; i++) {
        final current = readings[i];

        totalConsumption += current.meterReading;
      }

      final days = _endDate!.difference(_startDate!).inDays + 1;
      final avgDailyConsumption = days > 0 ? totalDiesel / days : 0;
      final avgRate = dailyRates.isNotEmpty
          ? dailyRates.reduce((a, b) => a + b) / dailyRates.length
          : 0;

      setState(() {
        _readings = readings;
        _detailedReadings = detailedReadings;
        _summary = {
          'totalMeterReading': totalConsumption,
          'totalDieselConsumption': totalDiesel,
          'avgDieselRate': avgDailyConsumption,
          'avgDailyConsumption': avgDailyConsumption,
          'days': days,
          'avgRate': avgRate
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في توليد التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToPdf() async {
    if (_startDate == null ||
        _endDate == null ||
        _readings == null ||
        _readings!.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Generate PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateSolarAnalysisReport(
        solarSystem: widget.solar,
        startDate: _startDate!,
        endDate: _endDate!,
        summary: _summary,
        detailedReadings: _detailedReadings!,
      );

      // Share PDF
      await pdfService.sharePdf(pdfFile);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير التقرير بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // SummaryRow(
            //   icon: Icons.local_gas_station,
            //   label: 'إجمالي استهلاك الديزل',
            //   value:
            //       '${_summary['totalDieselConsumption']?.toStringAsFixed(2) ?? '0.00'} L',
            //   color: Colors.red,
            // ),
            const SizedBox(height: 8),
            SummaryRow(
              icon: Icons.solar_power,
              label: 'اجمالي الانتاج ',
              value:
                  '${_summary['totalMeterReading']?.toStringAsFixed(2) ?? '0.00'} kWh',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 8),
            SummaryRow(
              icon: Icons.calendar_today,
              label: 'عدد الأيام',
              value: '${_summary['days'] ?? '0'} يوم',
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            // SummaryRow(
            //   icon: Icons.trending_down,
            //   label: ' متوسط الاستهلاك اليومي',
            //   value:
            //       '${_summary['avgDailyConsumption']?.toStringAsFixed(2) ?? '0.00'} L/day',
            //   color: Colors.purple,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList() {
    if (_detailedReadings == null || _detailedReadings!.isEmpty) {
      return const Center(
        child: Text('لا يوجد نتائج'),
      );
    }

    return ListView.builder(
      itemCount: _detailedReadings!.length,
      itemBuilder: (context, index) {
        final readingData = _detailedReadings![index];
        final reading = readingData['readingObj'] as Reading;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.orange.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.power,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.solar.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Text(
                      readingData['date'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'القراءة : الإنتاج ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${reading.meterReading.toStringAsFixed(2)} kWh',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
