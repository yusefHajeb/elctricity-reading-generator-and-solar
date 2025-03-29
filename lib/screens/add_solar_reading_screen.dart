import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/reading.dart';
import '../models/solar_system.dart';
import '../service/database_service.dart';
import '../widget/costom_text_form_field.dart';

class AddSolarReadingScreen extends StatefulWidget {
  final SolarSystem solarSystem;
  final Reading? readingToEdit;

  const AddSolarReadingScreen({
    super.key,
    required this.solarSystem,
    this.readingToEdit,
  });

  @override
  State<AddSolarReadingScreen> createState() => _AddSolarReadingScreenState();
}

class _AddSolarReadingScreenState extends State<AddSolarReadingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _meterReadingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? _lastMeterReading;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  Reading? _existingReading;

  @override
  void initState() {
    super.initState();
    if (widget.readingToEdit != null) {
      _meterReadingController.text =
          widget.readingToEdit!.meterReading.toString();
      _selectedDate = widget.readingToEdit!.readingDate;
    }
    _loadLastReading();
  }

  Future<void> _loadLastReading() async {
    try {
      final readings = await _databaseService
          .getReadingsForSolarSystem(widget.solarSystem.id!);
      if (readings.isNotEmpty) {
        setState(() {
          _lastMeterReading = readings.first.meterReading;
        });
      }

      if (widget.readingToEdit == null) {
        _existingReading = await _databaseService.getReadingForDate(
          solarSystemId: widget.solarSystem.id!,
          date: _selectedDate,
        );
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل البيانات: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });

      try {
        _existingReading = await _databaseService.getReadingForDate(
          solarSystemId: widget.solarSystem.id!,
          date: _selectedDate,
        );
      } catch (e) {
        _showErrorSnackBar(
            'خطأ في التحقق من القراءات الموجودة: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _confirmReplace() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('توجد قراءة مسجلة'),
        content: Text(
          'توجد قراءة بالفعل ليوم ${DateFormat('dd/MM/yyyy').format(_selectedDate)}. '
          'هل تريد استبدالها؟',
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
            child: const Text('استبدال'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
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

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readingToEdit != null
            ? 'تعديل القراءة'
            : 'إضافة قراءة جديدة'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateCard(),
                    const SizedBox(height: 16),
                    if (_lastMeterReading != null) _buildLastReadingCard(),
                    const SizedBox(height: 16),
                    _buildReadingInputCard(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تاريخ القراءة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.readingToEdit != null ? null : _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
            if (_existingReading != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'توجد قراءة مسجلة لهذا اليوم',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القراءة السابقة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastMeterReading!.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القراءة الحالية',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _meterReadingController,
              label: 'أدخل القراءة',
              hint: 'أدخل قراءة العداد الحالية',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال القراءة';
                }
                final reading = double.tryParse(value);
                if (reading == null) {
                  return 'يجب أن تكون القراءة رقمية';
                }
                // if (_lastMeterReading != null &&
                //     reading <= _lastMeterReading!) {
                //   return 'يجب أن تكون القراءة أكبر من القراءة السابقة';
                // }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _submitReading,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving
            ? 'جاري الحفظ...'
            : (widget.readingToEdit != null ? 'تحديث القراءة' : 'حفظ القراءة')),
      ),
    );
  }

  Future<void> _submitReading() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingReading != null && widget.readingToEdit == null) {
      final shouldReplace = await _confirmReplace();
      if (shouldReplace != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final reading = Reading(
        id: widget.readingToEdit?.id,
        solarSystemId: widget.solarSystem.id!,
        meterReading: double.parse(_meterReadingController.text),
        readingDate: _selectedDate,
      );

      if (widget.readingToEdit != null) {
        await _databaseService.updateReading(reading);
        _showSuccessSnackBar('تم تحديث القراءة بنجاح');
      } else {
        await _databaseService.insertReading(reading);
        _showSuccessSnackBar('تم حفظ القراءة بنجاح');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ القراءة: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _meterReadingController.dispose();
    super.dispose();
  }
}
