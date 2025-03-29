import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reading.dart';

class ReadingListItem extends StatelessWidget {
  final Reading reading;
  final Reading? previousReading;
  final VoidCallback? onEdit;

  const ReadingListItem({
    super.key,
    required this.reading,
    this.previousReading,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final difference = previousReading != null
        ? reading.meterReading - previousReading!.meterReading
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(reading.readingDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    DateFormat('HH:mm').format(reading.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'القراءة الحالية:', reading.meterReading.toString()),
              _buildInfoRow('القراءة السابقة :',
                  previousReading?.meterReading.toString() ?? 'N/A'),
              _buildInfoRow(
                  'استهلاك الكيلوهات:', difference.toStringAsFixed(2)),
              if (reading.dieselConsumption != null) ...[
                _buildInfoRow('استهلاك الديزل:',
                    '${reading.dieselConsumption.toString()} L'),
                _buildInfoRow('الديزل:',
                    '${difference / (reading.dieselConsumption ?? 1)} KW/L'),
              ],
              if (onEdit != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل '),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
