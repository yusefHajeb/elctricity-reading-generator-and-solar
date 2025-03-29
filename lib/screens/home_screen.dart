import 'package:elctricity_info/screens/backup_restore_screen.dart';
import 'package:elctricity_info/screens/generator_screen.dart';
import 'package:elctricity_info/screens/reports_screen.dart';
import 'package:elctricity_info/screens/solar_system.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GeneratorsScreen(),
    SolarSystemsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'Backup & Restore',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupRestoreScreen(),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.power),
            label: 'المولدات',
          ),
          NavigationDestination(
            icon: Icon(Icons.solar_power),
            label: 'النظام الشمسي',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment),
            label: 'التقارير',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'المولدات';
      case 1:
        return 'الطاقة الشمسية';
      case 2:
        return 'التقارير';
      default:
        return 'تعقب الطاقة';
    }
  }
}
