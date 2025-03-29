import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reading.dart';

class SolarReadingListItem extends StatelessWidget {
  final Reading reading;
  final Reading? previousReading;
  final VoidCallback? onEdit;

  const SolarReadingListItem({
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(reading.readingDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(reading.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${difference.toStringAsFixed(2)} كيلو وات',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'القراءة الحالية:',
            '${reading.meterReading.toStringAsFixed(2)} كيلو وات',
          ),
          if (difference > 0)
            _buildInfoRow(
              context,
              'متوسط الإنتاج اليومي:',
              '${(difference / _daysBetween(reading.readingDate, previousReading?.readingDate)).toStringAsFixed(2)} كيلوواط/يوم',
              isInfo: true,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlighted = false,
    bool isInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isInfo
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : null,
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : isInfo
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
          ),
        ],
      ),
    );
  }

  int _daysBetween(DateTime from, DateTime? to) {
    if (to == null) return 1;
    return (from.difference(to).inHours / 24).ceil();
  }
}
