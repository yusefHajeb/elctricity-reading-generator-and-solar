import 'package:elctricity_info/core/app_colors.dart';
import 'package:elctricity_info/models/base_consumption.dart';
import 'package:elctricity_info/widget/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reading.dart';

import '../service/database_service.dart';
import '../service/pdf_service.dart';

class DateRangeReportScreen extends StatefulWidget {
  const DateRangeReportScreen({super.key});

  @override
  State<DateRangeReportScreen> createState() => _DateRangeReportScreenState();
}

class _DateRangeReportScreenState extends State<DateRangeReportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _startDate;
  DateTime? _endDate;
  List<Reading>? _readings;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير بين التواريخ'),
        actions: [
          if (_readings != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'تصدير PDF',
              onPressed: _exportToPdf,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_startDate!)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _selectDate(isStart: false),
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_endDate == null
                                    ? 'تأريخ النهاية'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_endDate!)),
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
                else if (_readings != null) ...[
                  Text(
                    'نتائج التقرير',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildGeneratorsReport(),
                  const SizedBox(height: 16),
                  // Expanded(
                  //   child: _buildReadingsList(),
                  // ),
                ],
              ],
            ),
          ),
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
      });
    }
  }

  Widget _buildGeneratorsReport() {
    if (_startDate == null || _endDate == null) return const SizedBox.shrink();
    return FutureBuilder<List<BaseConsumption>>(
      future: _databaseService.calculateGeneratorsConsumption(
          _startDate!, _endDate!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات متاحة'));
        }

        final generators = snapshot.data!;

        // حساب الإجماليات
        final totalConsumption =
            generators.fold(0.0, (sum, gen) => sum + gen.totalConsumption);

        final totalSolarConsumption = generators.fold(0.0, (sum, solar) {
          if (solar is SolarConsumption) {
            return sum + (solar).totalConsumption;
          }
          return sum;
        });

        final totalGeneratorConsumption = generators.fold(0.0, (sum, gen) {
          if (gen is GeneratorConsumption) {
            return sum + (gen).totalConsumption;
          }
          return sum;
        });

        final totalDiesel = generators.fold(
            0.0,
            (sum, gen) =>
                sum + ((gen is GeneratorConsumption) ? (gen).totalDiesel : 0));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان التقرير
              const Text(
                'تقرير استهلاك المولدات',
              ),
              const SizedBox(height: 16),

              // معلومات الفترة الزمنية
              Text(
                'الفترة من ${DateFormat('yyyy-MM-dd').format(_startDate!)} إلى ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
              ),
              const Divider(),

              // الإجماليات
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      SummaryRow(
                        icon: Icons.power_rounded,
                        label: 'اجمالي الانتاج',
                        value: '$totalConsumption kWh',
                        color: const Color.fromARGB(255, 232, 49, 70),
                      ),
                      SummaryRow(
                        icon: Icons.power,
                        label: 'إنتاج المولدات',
                        value: '$totalGeneratorConsumption kWh',
                        color: AppColors.generator,
                      ),
                      SummaryRow(
                        icon: Icons.solar_power,
                        label: 'إنتاج المنظومات',
                        value: '$totalSolarConsumption kWh',
                        color: AppColors.solarColor,
                      ),
                      SummaryRow(
                        icon: Icons.local_gas_station,
                        label: ' مجموع استهلاك الديزل ',
                        value: '$totalDiesel L',
                        color: Colors.red,
                      ),
                      // _buildSummaryRow(
                      //     'إجمالي استهلاك الديزل', '$totalDiesel لتر'),
                      // if (totalDiesel > 0)
                      //   _buildSummaryRow('متوسط كفاءة الديزل',
                      //       '${avgEfficiency.toStringAsFixed(2)} kWh/لتر'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 8),

              ...generators.map((gen) => _buildGeneratorCard(gen)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneratorCard(BaseConsumption gen) {
    return Card(
      shadowColor: (gen is GeneratorConsumption)
          ? AppColors.generator
          : AppColors.solarColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gen.generatorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (gen is GeneratorConsumption) ...[
              _buildDetailRow('القراءة الأولى', '${gen.startReading} kWh'),
              _buildDetailRow('القراءة الأخيرة', '${gen.endReading} kWh'),
              _buildDetailRow(
                  'إجمالي الإنتاج', '${gen.totalConsumption} kWh'),
              _buildDetailRow('إجمالي الديزل', '${gen.totalDiesel} لتر'),
            ] else ...[
              // _buildDetailRow('القراءة الأولى', '${gen.startReading} kWh'),
              // _buildDetailRow('القراءة الأخيرة', '${gen.endReading} kWh'),
              _buildDetailRow('إجمالي الإنتاج', '${gen.totalConsumption} kWh'),
            ],
            // if (gen is GeneratorConsumption)
            // _buildDetailRow('إجمالي الديزل', '${gen.totalDiesel} لتر'),
            // if (gen is GeneratorConsumption)
            //   if (gen.totalDiesel > 0)
            //     _buildDetailRow(
            //         'الكفاءة', '${gen.efficiency.toStringAsFixed(2)} kWh/لتر'),
            // _buildDetailRow('عدد القراءات', gen.readingCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get readings using the database service
      final readings = await _databaseService.getReadingsByDateRange(
        _startDate!.subtract(const Duration(days: 1)),
        _endDate!,
      );

      // Get detailed readings using the provider
      // final detailedReadings =
      //     await Provider.of<ReportsProvider>(context, listen: false)
      //         .getReadingsForDateRange(_startDate!, _endDate!);

      setState(() {
        _readings = readings;
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
    if (_startDate == null || _endDate == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get generators consumption data
      final generators = await _databaseService.calculateGeneratorsConsumption(
          _startDate!, _endDate!);

      // Calculate totals
      final totalConsumption =
          generators.fold(0.0, (sum, gen) => sum + gen.totalConsumption);

      final totalSolarConsumption = generators.fold(0.0, (sum, solar) {
        if (solar is SolarConsumption) {
          return sum + (solar).totalConsumption;
        }
        return sum;
      });

      final totalGeneratorConsumption = generators.fold(0.0, (sum, gen) {
        if (gen is GeneratorConsumption) {
          return sum + (gen).totalConsumption;
        }
        return sum;
      });

      final totalDiesel = generators.fold(
          0.0,
          (sum, gen) =>
              sum + ((gen is GeneratorConsumption) ? (gen).totalDiesel : 0));

      // Generate PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateDateRangeReport(
        startDate: _startDate!,
        endDate: _endDate!,
        generators: generators,
        totalConsumption: totalConsumption,
        totalSolarConsumption: totalSolarConsumption,
        totalGeneratorConsumption: totalGeneratorConsumption,
        totalDiesel: totalDiesel,
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
}
