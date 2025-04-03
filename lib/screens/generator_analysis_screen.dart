import 'package:elctricity_info/core/app_colors.dart';
import 'package:elctricity_info/widget/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/generator.dart';
import '../models/reading.dart';
import '../providers/reports_provider.dart';
import '../service/database_service.dart';
import '../service/pdf_service.dart';

class GeneratorAnalysisScreen extends StatefulWidget {
  final Generator generator;

  const GeneratorAnalysisScreen({
    super.key,
    required this.generator,
  });

  @override
  State<GeneratorAnalysisScreen> createState() =>
      _GeneratorAnalysisScreenState();
}

class _GeneratorAnalysisScreenState extends State<GeneratorAnalysisScreen> {
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
        title: Text('${widget.generator.name} تحليل'),
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

    setState(() => _isLoading = true);

    try {
      final readings = await _databaseService.getReadingsWithFallbackStartDate(
        startDate: _startDate!.subtract(const Duration(days: 1)),
        endDate: _endDate!,
        generatorId: widget.generator.id,
      );

      // الترتيب التصاعدي مهم للحساب
      readings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

      double totalConsumption = 0;
      double totalDiesel = 0;
      List<double> dailyRates = [];
      for (int i = 1; i < readings.length; i++) {
        final current = readings[i];
        final previous = readings[i - 1];

        final diff = current.meterReading - previous.meterReading;
        totalConsumption += diff;

        if (current.dieselConsumption != null &&
            current.dieselConsumption! > 0) {
          totalDiesel += current.dieselConsumption!;
          dailyRates.add(diff / current.dieselConsumption!);
        }
      }

      final days = _endDate!.difference(_startDate!).inDays + 1;
      final avgRate = dailyRates.isNotEmpty
          ? dailyRates.reduce((a, b) => a + b) / dailyRates.length
          : 0;

      //new
      final reportsProvider =
          Provider.of<ReportsProvider>(context, listen: false);

      final allDetailedReadings =
          await reportsProvider.getReadingsForDateRange(_startDate!, _endDate!);

      // Filter for only this generator
      final detailedReadings = allDetailedReadings
          .where((reading) =>
              reading['type'] == 'generator' &&
              reading['id'] == widget.generator.id)
          .toList();

      setState(() {
        _readings = readings;
        _detailedReadings = detailedReadings;

        _summary = {
          'totalConsumption': totalConsumption,
          'totalDiesel': totalDiesel,
          'avgRate': avgRate,
          'days': days,
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
      // معالجة الأخطاء...
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
      final pdfFile = await pdfService.generateGeneratorAnalysisReport(
        generator: widget.generator,
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
            SummaryRow(
              icon: Icons.local_gas_station,
              label: 'الإنتاج الكلي',
              value:
                  '${_summary['totalConsumption']?.toStringAsFixed(2) ?? '0.00'} kWh',
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            SummaryRow(
              icon: Icons.power,
              label: 'استهلاك الديزل',
              value:
                  '${_summary['totalDiesel']?.toStringAsFixed(2) ?? '0.00'} L',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            // SummaryRow(
            //   icon: Icons.speed,
            //   label: 'متوسط معدل الديزل',
            //   value:
            //       '${_summary['avgRate']?.toStringAsFixed(2) ?? '0.00'} kWh/L',
            //   color: Colors.blue,
            // ),
            const SizedBox(height: 8),
            SummaryRow(
              icon: Icons.calendar_today,
              label: 'عدد الأيام',
              value: '${_summary['days'] ?? '0'} يوم',
              color: Colors.green,
            ),
            const SizedBox(height: 8),
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
          color: AppColors.generator.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.power,
                      color: AppColors.generator,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.generator.name,
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
                      'القراءة:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${reading.meterReading.toStringAsFixed(2)} kWh',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (reading.dieselConsumption != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'استهلاك الديزل:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${reading.dieselConsumption!.toStringAsFixed(2)} L',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'معدل الاستهلاك:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${readingData['dieselRate']?.toStringAsFixed(2) ?? 'N/A'} L/kWh',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
