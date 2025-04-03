import 'package:elctricity_info/models/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

    setState(() {
      _isLoading = false;
    });
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
        solarSystemId: widget.solarSystem.id!,
        date: _selectedDate,
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _confirmReplace() async {
  //   return showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Reading Already Exists'),
  //       content: Text(
  //         'توجد قراءة بالفعل لـ ${DateFormat('dd/MM/yyyy').format(_selectedDate)}. '
  //         'هل تريد استبدالها؟',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('الغاء '),
  //         ),
  //         FilledButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('استبدال'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.readingToEdit != null ? 'تعديل القراءة ' : 'اضافة القراءة '),
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
                            Text(
                              'اختر التأريخ',
                              style: Theme.of(context).textTheme.titleMedium,
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
                                'تحذير: تم العثور على قراءة موجودة لهذا التاريخ',
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
                    if (_lastMeterReading != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'القراءة السابقة ',
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
                      label: 'Meter Reading',
                      hint: 'Enter current meter reading',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ادخل القراءة ';
                        }
                        final reading = double.tryParse(value);
                        if (reading == null) {
                          return 'يجب ان تكون القراءة رقمية';
                        }
                        // if (_lastMeterReading != null &&
                        //     reading <= _lastMeterReading!) {
                        //   return 'New reading must be greater than the last reading';
                        // }
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
                            ? 'تعديل القراءة '
                            : 'حفظ القراءة '),
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
        // final shouldReplace = await _confirmReplace();
        // if (shouldReplace != true) return;
      }

      final reading = Reading(
        id: widget.readingToEdit?.id,
        solarSystemId: widget.solarSystem.id!,
        meterReading: double.parse(_meterReadingController.text),
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
                  ? 'القراءة تم تحديثها بنجاح'
                  : 'القراءة تم اضافتها بنجاح'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString()}'),
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
    super.dispose();
  }
}
