import 'package:flutter/material.dart';
import '../models/generator.dart';
import '../service/database_service.dart';

class ConsumptionAnalysisScreen extends StatefulWidget {
  final Generator generator;

  const ConsumptionAnalysisScreen({
    super.key,
    required this.generator,
  });

  @override
  State<ConsumptionAnalysisScreen> createState() =>
      _ConsumptionAnalysisScreenState();
}

class _ConsumptionAnalysisScreenState extends State<ConsumptionAnalysisScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.generator.name} تحليل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Text(_startDate != null
                        ? 'Start: ${_startDate.toString().split(' ')[0]}'
                        : 'اختر تأريخ البداية'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Text(_endDate != null
                        ? 'End: ${_endDate.toString().split(' ')[0]}'
                        : 'اختر تأريخ النهاية'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_startDate != null && _endDate != null)
              FutureBuilder<double>(
                future: _databaseService.getAverageDieselConsumption(
                  widget.generator.id!,
                  _startDate!,
                  _endDate!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نتيجة التقرير',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'متوسط الاستهلاك اليومي للديزل:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.data?.toStringAsFixed(2) ?? "0.00"} L/day',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
