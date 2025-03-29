import 'package:elctricity_info/core/app_snack_bar.dart';
import 'package:elctricity_info/screens/add_reading_screen.dart';
import 'package:elctricity_info/screens/generator_analysis_screen.dart';
import 'package:elctricity_info/service/database_service.dart';
import 'package:elctricity_info/widget/reading_list_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/generator.dart';
import '../models/reading.dart';

class GeneratorDetailsScreen extends StatefulWidget {
  final Generator generator;

  const GeneratorDetailsScreen({
    super.key,
    required this.generator,
  });

  @override
  State<GeneratorDetailsScreen> createState() => _GeneratorDetailsScreenState();
}

class _GeneratorDetailsScreenState extends State<GeneratorDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _editReading(Reading reading) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddReadingScreen(
          generator: widget.generator,
          readingToEdit: reading,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<bool?> _deleteReading(Reading reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القراءة'),
        content: Text(
          'هل أنت متأكد من حذف قراءة '
          '${DateFormat('dd/MM/yyyy').format(reading.readingDate)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteReading(reading.id!);
        if (mounted) {
          AppSnackBar.showSuccessMessage('تم حذف القراءة بنجاح', context);
          setState(() {});
          return true;
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showErrorMessage(
              'خطأ في حذف القراءة: ${e.toString()}', context);
        }
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.generator.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Analysis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GeneratorAnalysisScreen(
                    generator: widget.generator,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Reading>>(
        future: _databaseService.getReadingsForGenerator(widget.generator.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speed_outlined,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد قراءات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف قراءتك الأولى لبدء التتبع!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          final readings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index];

              final previousReading =
                  index < readings.length - 1 ? readings[index + 1] : null;
              return Dismissible(
                key: Key('reading-${reading.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return _deleteReading(reading);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: ReadingListItem(
                  reading: reading,
                  previousReading: previousReading,
                  // onEdit: () => _editReading(reading),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddReadingScreen(generator: widget.generator),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        label: const Text('اضافة قراءة'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
