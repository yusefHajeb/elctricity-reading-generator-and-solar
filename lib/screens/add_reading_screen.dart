import 'package:elctricity_info/service/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/generator.dart';
import '../models/reading.dart';
import '../widget/costom_text_form_field.dart';
import 'package:intl/intl.dart';

class AddReadingScreen extends StatefulWidget {
  final Generator generator;
  final Reading? readingToEdit;

  const AddReadingScreen({
    super.key,
    required this.generator,
    this.readingToEdit,
  });

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _meterReadingController = TextEditingController();
  final TextEditingController _dieselConsumptionController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? _lastMeterReading = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  Reading? _existingReading;

  @override
  void initState() {
    super.initState();
    if (widget.readingToEdit != null) {
      _meterReadingController.text =
          widget.readingToEdit!.meterReading.toString();
      _dieselConsumptionController.text =
          widget.readingToEdit!.dieselConsumption?.toString() ?? '';
      _selectedDate = widget.readingToEdit!.readingDate;
    }
    _loadLastReading();
  }

  Future<void> _loadLastReading() async {
    final readings =
        await _databaseService.getReadingsForGenerator(widget.generator.id!);
    if (readings.isNotEmpty) {
      setState(() {
        _lastMeterReading = readings.first.meterReading;
      });
    }

    if (widget.readingToEdit == null) {
      _existingReading = await _databaseService.getReadingForDate(
        generatorId: widget.generator.id!,
        date: _selectedDate,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<double?> _loadLastDateReading(DateTime date) async {
    // Try to get the last reading for the initial date
    var lastReading = await _databaseService.getReadingForDate(
        date: date, generatorId: widget.generator.id);

    // If found, return the meter reading
    if (lastReading != null) {
      return lastReading.meterReading;
    }

    // Loop through previous dates until a reading is found or we reach a limit
    for (int daysAgo = 1; daysAgo <= 30; daysAgo++) {
      // Set a limit (e.g., 30 days)
      lastReading = await _databaseService.getReadingForDate(
          date: date.subtract(Duration(days: daysAgo)),
          generatorId: widget.generator.id);

      if (lastReading != null) {
        setState(() {
          // Here you might want to update some state if necessary
        });
        return lastReading.meterReading;
      }
    }

    // Return null if no reading is found after the loop
    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });

      _existingReading = await _databaseService.getReadingForDate(
        generatorId: widget.generator.id!,
        date: _selectedDate,
      );

      _lastMeterReading = await _loadLastDateReading(_selectedDate) ?? 0;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirmReplace() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قراءة موجودة بالفعل'),
        content: Text(
          'توجد قراءة بالفعل لـ ${DateFormat('dd/MM/yyyy').format(_selectedDate)}. '
          'هل تريد استبدالها',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('الغاء '),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('استبدال'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.readingToEdit != null ? 'تعديل التأريخ' : 'اضافة التأريخ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حدد التأريخ',
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.readingToEdit != null
                                    ? null
                                    : _selectDate,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_selectedDate),
                                ),
                              ),
                            ),
                            if (_existingReading != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'تحذير: توجد قراءة بالفعل لهذا التاريخ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.orange),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_lastMeterReading != 0) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'القراءة السابقة',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _lastMeterReading!.toString(),
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    CustomTextField(
                      controller: _meterReadingController,
                      label: 'الكيلوهات الكلية',
                      hint: 'أدخل قراءة العداد الحالية',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى ادخال قيمة رقمي';
                        }
                        final reading = double.tryParse(value);
                        if (reading == null) {
                          return 'يرجى ادخال قيمة رقمي';
                        }
                        if (_lastMeterReading != null &&
                            reading <= _lastMeterReading!) {
                          return 'القراءة الحالية اقل من القراءة السابقة ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _dieselConsumptionController,
                      label: 'استهلاك الديزل',
                      hint: 'ادخل استهلاك الديزل',
                      suffixText: 'L',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى ادخال استهلاك الديزل';
                        }
                        if (double.tryParse(value) == null) {
                          return 'يرجى ادخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitReading,
                        icon: const Icon(Icons.save),
                        label: Text(widget.readingToEdit != null
                            ? 'تعديل القراءة'
                            : 'حفظ القراءة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitReading() async {
    if (_formKey.currentState!.validate()) {
      if (_existingReading != null && widget.readingToEdit == null) {
        final shouldReplace = await _confirmReplace();
        if (shouldReplace != true) return;
      }

      final reading = Reading(
        id: widget.readingToEdit?.id,
        generatorId: widget.generator.id!,
        meterReading: double.parse(_meterReadingController.text),
        dieselConsumption: double.parse(_dieselConsumptionController.text),
        readingDate: _selectedDate,
      );

      try {
        if (widget.readingToEdit != null) {
          await _databaseService.updateReading(reading);
        } else {
          await _databaseService.insertReading(reading);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.readingToEdit != null
                  ? 'تم تحديث القراءة بنجاح'
                  : 'تم إضافة القراءة بنجاح'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.greenAccent,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _meterReadingController.dispose();
    _dieselConsumptionController.dispose();
    super.dispose();
  }
}
