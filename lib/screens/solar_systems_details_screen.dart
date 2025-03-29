import 'package:elctricity_info/screens/add_solar_reading_screen.dart';
import 'package:elctricity_info/screens/solar_analysis_screen.dart';
import 'package:elctricity_info/widget/solar_reading_list_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/solar_system.dart';
import '../models/reading.dart';
import '../service/database_service.dart';

class SolarSystemDetailsScreen extends StatefulWidget {
  final SolarSystem solarSystem;

  const SolarSystemDetailsScreen({
    super.key,
    required this.solarSystem,
  });

  @override
  State<SolarSystemDetailsScreen> createState() =>
      _SolarSystemDetailsScreenState();
}

class _SolarSystemDetailsScreenState extends State<SolarSystemDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  Future<void> _editReading(Reading reading) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSolarReadingScreen(
          solarSystem: widget.solarSystem,
          readingToEdit: reading,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<bool> _deleteReading(Reading reading) async {
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
      setState(() => _isLoading = true);
      try {
        await _databaseService.deleteReading(reading.id!);
        if (mounted) {
          _showSuccessMessage('تم حذف القراءة بنجاح');
        }
        return true;
      } catch (e) {
        if (mounted) {
          _showErrorMessage('خطأ في حذف القراءة: ${e.toString()}');
        }
        return false;
      } finally {
        setState(() => _isLoading = false);
      }
    }
    return false;
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<List<Reading>> _fetchReadings() async {
    return _databaseService.getReadingsForSolarSystem(widget.solarSystem.id!);
  }

  Widget _buildSystemInfoCard(List<Reading> readings) {
    final hasReadings = readings.isNotEmpty;
    final latestReading = hasReadings ? readings.first.meterReading : 0.0;
    final firstReading = hasReadings ? readings.last.meterReading : 0.0;
    final totalProduction = hasReadings ? latestReading - firstReading : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.solar_power,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'معلومات النظام',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('الاسم:', widget.solarSystem.name),
            _buildInfoRow(
              'تاريخ الإنشاء:',
              DateFormat('dd/MM/yyyy').format(widget.solarSystem.createdAt),
            ),
            if (hasReadings) ...[
              _buildInfoRow(
                'آخر قراءة:',
                '${latestReading.toStringAsFixed(2)} كيلوواط',
              ),
              _buildInfoRow(
                'إجمالي الإنتاج:',
                '${totalProduction.toStringAsFixed(2)} كيلوواط',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.solarSystem.name),
            Text(
              'تفاصيل النظام الشمسي',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Analysis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SolarAnalysisScreen(
                    solar: widget.solarSystem,
                  ),
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: FutureBuilder<List<Reading>>(
              future: _fetchReadings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل البيانات...'),
                      ],
                    ),
                  );
                }

                final readings = snapshot.data ?? [];

                if (readings.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    _buildSystemInfoCard(readings),
                    Expanded(
                      child: _buildReadingsList(readings),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddSolarReadingScreen(solarSystem: widget.solarSystem),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              },
        label: const Text('إضافة قراءة'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.solar_power,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSolarReadingScreen(solarSystem: widget.solarSystem),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة قراءة جديدة'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList(List<Reading> readings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: readings.length,
      itemBuilder: (context, index) {
        final reading = readings[index];
        final previousReading =
            index < readings.length - 1 ? readings[index + 1] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Dismissible(
            key: Key('reading-${reading.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _deleteReading(reading),
            background: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_forever,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حذف',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SolarReadingListItem(
                reading: reading,
                previousReading: previousReading,
                onEdit: () => _editReading(reading),
              ),
            ),
          ),
        );
      },
    );
  }
}
