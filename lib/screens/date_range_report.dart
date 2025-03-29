import 'package:elctricity_info/models/base_consumption.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reading.dart';
import '../providers/reports_provider.dart';
import '../service/database_service.dart';

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
        // final totalDiesel = generators.fold<double>(
        //   0,
        //   (sum, gen) =>
        //       sum +
        //       (gen is GeneratorConsumption &&
        //               gen.startReading !=
        //                   _startDate!.subtract(const Duration(days: 1))
        //           ? gen.totalDiesel
        //           : 0),
        // );

        final avgEfficiency =
            totalDiesel > 0 ? totalConsumption / totalDiesel : 0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // physics: const NeverScrollableScrollPhysics(),
            // scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            // crossAxisAlignment: CrossAxisAlignment.start,
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
                      // const Text(
                      //   'الإجمالي لجميع المولدات',
                      //   style: TextStyle(
                      //       fontWeight: FontWeight.bold, fontSize: 18),
                      // ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        icon: Icons.power,
                        label: 'استهلاك المولدات',
                        value: '$totalConsumption kWh',
                        color: Colors.orange,
                      ),
                      _SummaryRow(
                        icon: Icons.solar_power,
                        label: 'استهلاك المنظومات',
                        value: '$totalSolarConsumption kWh',
                        color: const Color.fromARGB(255, 39, 154, 237),
                      ),
                      _SummaryRow(
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

              // Expanded(
              //   child: ListView.builder(
              //     physics: const NeverScrollableScrollPhysics(),
              //     itemBuilder: (context, index) {
              //       return _buildGeneratorCard(generators[index]);
              //     },
              //     itemCount: generators.length,
              //   ),
              // )
              ...generators.map((gen) => _buildGeneratorCard(gen)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneratorCard(BaseConsumption gen) {
    return Card(
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
            _buildDetailRow('القراءة الأولى', '${gen.startReading} kWh'),
            _buildDetailRow('القراءة الأخيرة', '${gen.endReading} kWh'),
            _buildDetailRow('إجمالي الاستهلاك', '${gen.totalConsumption} kWh'),
            if (gen is GeneratorConsumption)
              _buildDetailRow('إجمالي الديزل', '${gen.totalDiesel} لتر'),
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
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
      final detailedReadings =
          await Provider.of<ReportsProvider>(context, listen: false)
              .getReadingsForDateRange(_startDate!, _endDate!);

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

  // Widget _buildSummaryCard() {
  //   if (_readings == null) return const SizedBox.shrink();

  //   double totalGeneratorConsumption = 0;
  //   double totalSolarConsumption = 0;
  //   double totalDieselConsumption = 0;
  //   List<double> dailyRates = [];

  //   _readings?.sort((a, b) => a.readingDate.compareTo(b.readingDate));
  //   log('readings: ${_readings!.length}');

  //   if (_readings != null && (_readings!.isNotEmpty)) {
  //     for (int i = 1; i < _readings!.length; i++) {
  //       final current = _readings![i];
  //       final previous = _readings![i - 1];

  //       if (current.generatorId != null) {
  //         final diff = current.meterReading - previous.meterReading;
  //         totalGeneratorConsumption += diff;
  //         if (current.dieselConsumption != null) {
  //           totalDieselConsumption += current.dieselConsumption!;
  //         }
  //       } else if (current.solarSystemId != null) {
  //         totalSolarConsumption += current.meterReading - previous.meterReading;
  //       }
  //     }
  //   }

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'الملخص',
  //             style: Theme.of(context).textTheme.titleMedium,
  //           ),
  //           const SizedBox(height: 16),
  //           _SummaryRow(
  //             icon: Icons.power,
  //             label: 'استهلاك المولد',
  //             value: '$totalGeneratorConsumption kWh',
  //             color: Colors.orange,
  //           ),
  //           const SizedBox(height: 8),
  //           _SummaryRow(
  //             icon: Icons.solar_power,
  //             label: 'استهلاك المنظومة الشمسية',
  //             value: '$totalSolarConsumption kWh',
  //             color: Colors.green,
  //           ),
  //           const SizedBox(height: 8),
  //           _SummaryRow(
  //             icon: Icons.local_gas_station,
  //             label: ' مجموع استهلاك الديزل ',
  //             value: '$totalDieselConsumption L',
  //             color: Colors.red,
  //           ),
  //           if (totalDieselConsumption > 0 &&
  //               totalGeneratorConsumption > 0) ...[
  //             const SizedBox(height: 8),
  //             _SummaryRow(
  //               icon: Icons.speed,
  //               label: 'متوسط معدل الديزل',
  //               value:
  //                   '${(totalDieselConsumption / totalGeneratorConsumption).toStringAsFixed(2)} L/kW',
  //               color: Colors.blue,
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildReadingsList() {
  //   if (_detailedReadings == null || _detailedReadings!.isEmpty) {
  //     return const Center(
  //       child: Text('لا يوجد نتائج'),
  //     );
  //   }

  //   return ListView.builder(
  //     itemCount: _detailedReadings!.length,
  //     itemBuilder: (context, index) {
  //       final readingData = _detailedReadings![index];
  //       final reading = readingData['readingObj'] as Reading;
  //       final isGenerator = readingData['type'] == 'generator';

  //       return Card(
  //         margin: const EdgeInsets.symmetric(vertical: 4),
  //         color: isGenerator
  //             ? Colors.orange.withOpacity(0.05)
  //             : Colors.green.withOpacity(0.05),
  //         child: Padding(
  //           padding: const EdgeInsets.all(12.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(
  //                     isGenerator ? Icons.power : Icons.solar_power,
  //                     color: isGenerator ? Colors.orange : Colors.green,
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       readingData['name'] ??
  //                           (isGenerator ? 'مولد' : 'منظومة شمسية'),
  //                       style:
  //                           Theme.of(context).textTheme.titleMedium?.copyWith(
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                     ),
  //                   ),
  //                   Text(
  //                     readingData['date'] ?? '',
  //                     style: Theme.of(context).textTheme.bodyMedium,
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'القراءة:',
  //                     style: Theme.of(context).textTheme.bodyMedium,
  //                   ),
  //                   Text(
  //                     '${reading.meterReading.toStringAsFixed(2)} kWh',
  //                     style: Theme.of(context).textTheme.titleMedium,
  //                   ),
  //                 ],
  //               ),
  //               if (isGenerator && reading.dieselConsumption != null) ...[
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       'استهلاك الديزل:',
  //                       style: Theme.of(context).textTheme.bodyMedium,
  //                     ),
  //                     Text(
  //                       '${reading.dieselConsumption!.toStringAsFixed(2)} L',
  //                       style: Theme.of(context).textTheme.titleMedium,
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       'معدل الاستهلاك:',
  //                       style: Theme.of(context).textTheme.bodyMedium,
  //                     ),
  //                     Text(
  //                       '${readingData['dieselRate']?.toStringAsFixed(2) ?? 'N/A'} L/kWh',
  //                       style: Theme.of(context).textTheme.titleMedium,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
