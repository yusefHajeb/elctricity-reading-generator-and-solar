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
                    'No solar systems found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add one to get started!',
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
                    'الانشاء في ${solarSystem.createdAt.toIso8601String().split('T')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
          title: const Text('اضافة مولد طاقة شمسية'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              label: 'اسم المولد ',
              hint: 'اسم المولد الطاقة الشمسية',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى ادخال الاسم ';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
