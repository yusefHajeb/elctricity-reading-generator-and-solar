import 'dart:convert';
import 'dart:io';

import 'package:elctricity_info/service/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _backupData;
  bool _isLoading = false;
  Map<String, dynamic>? _backupMetadata;

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      final backup = await _databaseService.exportDatabase();
      final backupStr = jsonEncode(backup);

      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(path.join(dir.path, 'backup_$timestamp.json'));
      await file.writeAsString(backupStr);

      setState(() {
        _backupData = backupStr;
        _backupMetadata = _extractMetadata(backup);
      });

      _showSuccessMessage('تم إنشاء النسخة الاحتياطية بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إنشاء النسخة الاحتياطية: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _extractMetadata(Map<String, dynamic> backup) {
    return {
      'تاريخ النسخ':
          DateTime.parse(backup['backup_date']).toString().split('.')[0],
      'عدد المولدات': (backup['generators'] as List).length,
      'عدد أنظمة الطاقة الشمسية': (backup['solar_systems'] as List).length,
      'عدد القراءات': (backup['readings'] as List).length,
    };
  }

  Future<void> _shareBackup() async {
    if (_backupData == null) {
      _showErrorMessage('لا توجد نسخة احتياطية للمشاركة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(path.join(dir.path, 'backup_$timestamp.json'));
      await file.writeAsString(_backupData!);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'نسخة احتياطية من بيانات التطبيق',
        text:
            'نسخة احتياطية تم إنشاؤها في ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      _showErrorMessage('خطأ في مشاركة النسخة الاحتياطية: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _validateBackupData(String data) {
    try {
      final backup = jsonDecode(data);
      if (backup is! Map<String, dynamic>) return Future.value(false);

      // Check required fields
      final requiredFields = [
        'version',
        'backup_date',
        'generators',
        'solar_systems',
        'readings'
      ];

      if (!requiredFields.every((field) => backup.containsKey(field))) {
        return Future.value(false);
      }

      // Validate version
      if (backup['version'] > 2) {
        return Future.value(false);
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_backupData == null) return;

    final isValid = await _validateBackupData(_backupData!);
    if (!isValid) {
      _showErrorMessage('بيانات النسخة الاحتياطية غير صالحة');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'سيؤدي هذا إلى استبدال جميع البيانات الحالية ببيانات النسخة الاحتياطية. '
          'لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد من المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final backupMap = jsonDecode(_backupData!);
      await _databaseService.importDatabase(backupMap);
      _showSuccessMessage('تمت استعادة النسخة الاحتياطية بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorMessage('خطأ في استعادة النسخة الاحتياطية: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  Future<void> _copyToClipboard() async {
    if (_backupData == null) {
      _showErrorMessage('لا توجد نسخة احتياطية للنسخ');
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _backupData!));
      if (mounted) {
        _showSuccessMessage('تم نسخ النسخة الاحتياطية إلى الحافظة');
      }
    } catch (e) {
      _showErrorMessage('خطأ في نسخ النسخة الاحتياطية: $e');
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;

      if (text == null || text.isEmpty) {
        _showErrorMessage('لا توجد بيانات في الحافظة');
        return;
      }

      final isValid = await _validateBackupData(text);
      if (!isValid) {
        _showErrorMessage('بيانات النسخة الاحتياطية غير صالحة');
        return;
      }

      final backupMap = jsonDecode(text);
      setState(() {
        _backupData = text;
        _backupMetadata = _extractMetadata(backupMap);
      });

      _showSuccessMessage('تم استيراد النسخة الاحتياطية بنجاح');
    } on FormatException {
      _showErrorMessage('تنسيق البيانات غير صالح');
    } catch (e) {
      _showErrorMessage('خطأ في استيراد البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري المعالجة...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCreateBackupCard(),
                  const SizedBox(height: 16),
                  if (_backupData != null) ...[
                    _buildBackupDetailsCard(),
                    const SizedBox(height: 16),
                    _buildRestoreBackupCard(),
                  ] else
                    _buildPasteBackupCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildCreateBackupCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined, size: 24),
                const SizedBox(width: 8),
                Text(
                  'إنشاء نسخة احتياطية',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'قم بإنشاء نسخة احتياطية من جميع بياناتك بما في ذلك المولدات '
              'وأنظمة الطاقة الشمسية والقراءات.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupDetailsCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'تفاصيل النسخة الاحتياطية',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Tooltip(
                      message: 'نسخ إلى الحافظة',
                      child: IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Tooltip(
                      message: 'مشاركة',
                      child: IconButton(
                        onPressed: _shareBackup,
                        icon: const Icon(Icons.share),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_backupMetadata != null)
              ...(_backupMetadata!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(entry.value.toString()),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreBackupCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restore, size: 24),
                const SizedBox(width: 8),
                Text(
                  'استعادة النسخة الاحتياطية',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'استعد بياناتك من النسخة الاحتياطية. سيؤدي هذا إلى استبدال '
              'جميع البيانات الحالية.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('استعادة النسخة الاحتياطية'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteBackupCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.paste, size: 24),
                const SizedBox(width: 8),
                Text(
                  'استيراد من الحافظة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'الصق نسخة احتياطية سابقة لاستعادة بياناتك.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste),
                label: const Text('لصق من الحافظة'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
