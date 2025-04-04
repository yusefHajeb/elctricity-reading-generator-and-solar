import 'package:elctricity_info/screens/solar_systems_details_screen.dart';
import 'package:flutter/material.dart';
import '../models/solar_system.dart';
import '../service/database_service.dart';
import '../widget/costom_text_form_field.dart';

class SolarSystemsScreen extends StatefulWidget {
  const SolarSystemsScreen({super.key});

  @override
  State<SolarSystemsScreen> createState() => _SolarSystemsScreenState();
}

class _SolarSystemsScreenState extends State<SolarSystemsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SolarSystem>>(
        future: _databaseService.getSolarSystems(),
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
                    Icons.solar_power,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد بيانات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'فم ب اضافة بيانات',
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
              final solarSystem = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.solar_power),
                  ),
                  title: Text(solarSystem.name),
                  subtitle: Text(
                    'تأريخ الانشاء  ${solarSystem.createdAt.toIso8601String().split('T')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditSolarSystemDialog(solarSystem),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(solarSystem),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolarSystemDetailsScreen(
                          solarSystem: solarSystem,
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
        onPressed: _showAddSolarSystemDialog,
        label: const Text('اضافة منظومة شمسية'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddSolarSystemDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اضافة منظومة شمسية'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              label: 'اسم المولد ',
              hint: 'اسم المنظومة الشمسية',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى ادخال الاسم ';
                }
                if (value.length < 3) {
                  return 'ينبغي ان يكون الاسم اكبر من ثلاث حروف';
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
                  final solarSystem = SolarSystem(
                    name: _nameController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await _databaseService.insertSolarSystem(solarSystem);
                  _nameController.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('اضافة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSolarSystemDialog(SolarSystem solarSystem) async {
    _nameController.text = solarSystem.name;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المنظومة الشمسية'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              label: 'اسم المنظومة',
              hint: 'ادخل اسم المنظومة الشمسية',
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
                  final updatedSolarSystem = SolarSystem(
                    id: solarSystem.id,
                    name: _nameController.text.trim(),
                    createdAt: solarSystem.createdAt,
                  );
                  await _databaseService.updateSolarSystem(updatedSolarSystem);
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

  Future<void> _showDeleteConfirmationDialog(SolarSystem solarSystem) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المنظومة الشمسية'),
          content: Text(
              'هل انت متأكد من حذف المنظومة "${solarSystem.name}"؟ سيتم حذف جميع القراءات المرتبطة بها.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('الغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await _databaseService.deleteSolarSystem(solarSystem.id!);
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
