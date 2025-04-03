import 'package:elctricity_info/providers/reports_provider.dart';
import 'package:elctricity_info/screens/date_range_report.dart';
import 'package:elctricity_info/widget/about_developer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'export_data_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         // Row(
              //         //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         //   children: [
              //         //     Text(
              //         //       'الاستهلاك اليومي ',
              //         //       style: Theme.of(context).textTheme.titleLarge,
              //         //     ),
              //         //     TextButton.icon(
              //         //       onPressed: () async {
              //         //         final date = await showDatePicker(
              //         //           context: context,
              //         //           initialDate: reportsProvider.selectedDate,
              //         //           firstDate: DateTime(2000),
              //         //           lastDate: DateTime.now(),
              //         //         );
              //         //         if (date != null) {
              //         //           reportsProvider.setSelectedDate(date);
              //         //         }
              //         //       },
              //         //       icon: const Icon(Icons.calendar_today),
              //         //       label: Text(
              //         //         DateFormat('dd/MM/yyyy')
              //         //             .format(reportsProvider.selectedDate),
              //         //       ),
              //         //     ),
              //         //   ],
              //         // ),
              //         const SizedBox(height: 16),
              //         if (reportsProvider.isLoading)
              //           const Center(child: CircularProgressIndicator())
              //         else
              //           Column(
              //             children: [
              //               _ConsumptionTile(
              //                 icon: Icons.power,
              //                 title: 'استهلاك المولدات',
              //                 value: reportsProvider
              //                         .dailyConsumptionData['totalGenerator'] ??
              //                     0.0,
              //                 color: Colors.orange,
              //               ),
              //               const SizedBox(height: 8),
              //               _ConsumptionTile(
              //                 icon: Icons.solar_power,
              //                 title: 'استهلاك المنظومة الشمسية',
              //                 value: reportsProvider
              //                         .dailyConsumptionData['totalSolar'] ??
              //                     0.0,
              //                 color: Colors.green,
              //               ),
              //               const Divider(height: 32),
              //               _ConsumptionTile(
              //                 icon: Icons.bolt,
              //                 title: 'مجموع القراءات',
              //                 value: reportsProvider
              //                         .dailyConsumptionData['total'] ??
              //                     0.0,
              //                 color: Theme.of(context).colorScheme.primary,
              //                 large: true,
              //               ),
              //             ],
              //           ),
              //       ],
              //     ),
              //   ),
              // ),
              const SizedBox(height: 16),
              if (reportsProvider.detailedReadings.isNotEmpty) ...[
                Text(
                  'تفاصيل القراءات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: reportsProvider.detailedReadings.length,
                    itemBuilder: (context, index) {
                      final reading = reportsProvider.detailedReadings[index];
                      return _ReadingDetailCard(
                        reading: reading,
                      );
                    },
                  ),
                ),
              ] else if (!reportsProvider.isLoading) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'لا توجد قراءات لهذا اليوم',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DateRangeReportScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.date_range),
                      label: const Text('تقرير بين تأريخين'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExportDataScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('تصدير البيانات'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showDeveloperInfoDialog(context);
                  },
                  icon: const Icon(Icons.developer_board),
                  label: const Text('حول المطور'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadingDetailCard extends StatelessWidget {
  final Map<String, dynamic> reading;

  const _ReadingDetailCard({
    required this.reading,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGenerator = reading['type'] == 'generator';
    final Color cardColor = isGenerator
        ? Colors.orange.withOpacity(0.1)
        : Colors.green.withOpacity(0.1);
    final Color textColor = isGenerator ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGenerator ? Icons.power : Icons.solar_power,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reading['name'] ?? (isGenerator ? 'مولد' : 'منظومة شمسية'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  reading['date'] ?? '',
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
                  '${reading['reading']?.toStringAsFixed(2) ?? '0.00'} kWh',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (isGenerator && reading['dieselConsumption'] != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'استهلاك الديزل:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${reading['dieselConsumption']?.toStringAsFixed(2) ?? '0.00'} L',
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
                    '${reading['dieselRate']?.toStringAsFixed(2) ?? '0.00'} L/kWh',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
