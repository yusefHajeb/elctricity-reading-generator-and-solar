import 'package:elctricity_info/service/database_service.dart';
import 'package:elctricity_info/widget/costom_text_form_field.dart';
import 'package:flutter/material.dart';
import '../models/generator.dart';
import 'generator_details_screen.dart';

class GeneratorsScreen extends StatefulWidget {
  const GeneratorsScreen({super.key});

  @override
  State<GeneratorsScreen> createState() => _GeneratorsScreenState();
}

class _GeneratorsScreenState extends State<GeneratorsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المولدات'),
      ),
      body: FutureBuilder<List<Generator>>(
        future: _databaseService.getGenerators(),
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
                    Icons.power,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد مولدات مضافة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إبداء ب اضافة المولد الأول لبدء تتبع !',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final generator = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(generator.name[0].toUpperCase()),
                  ),
                  title: Text(generator.name),
                  subtitle: Text(
                    'تاريخ الانشاء  ${generator.createdAt.toIso8601String().split('T')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditGeneratorDialog(generator),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(generator),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GeneratorDetailsScreen(
                          generator: generator,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGeneratorDialog,
        label: const Text('أضف المولد'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddGeneratorDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اضافة مولد'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              label: 'اسم المولد',
              hint: 'ادخل اسم المولد',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى ادخال اسم المولد';
                }
                if (value.length < 3) {
                  return 'ينبغي ان يكون الاسم اكبر من ثلاثة حروف';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final generator = Generator(
                    name: _nameController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await _databaseService.insertGenerator(generator);
                  _nameController.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditGeneratorDialog(Generator generator) async {
    _nameController.text = generator.name;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المولد'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              label: 'اسم المولد',
              hint: 'ادخل اسم المولد',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى ادخال الاسم';
                }
                if (value.length < 3) {
                  return 'يجب ان يكون الاسم 3 احرف على الاقل';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                Navigator.pop(context);
              },
              child: const Text('الغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedGenerator = Generator(
                    id: generator.id,
                    name: _nameController.text.trim(),
                    createdAt: generator.createdAt,
                  );
                  await _databaseService.updateGenerator(updatedGenerator);
                  _nameController.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(Generator generator) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المولد'),
          content: Text(
              'هل انت متأكد من حذف المولد "${generator.name}"؟ سيتم حذف جميع القراءات المرتبطة به.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('الغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await _databaseService.deleteGenerator(generator.id!);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
