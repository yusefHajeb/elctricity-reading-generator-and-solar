import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/base_consumption.dart';
import '../models/generator.dart';
import '../models/reading.dart';
import '../models/solar_system.dart';

class PdfServiceO {
  // Singleton pattern
  static final PdfServiceO _instance = PdfServiceO._internal();
  factory PdfServiceO() => _instance;
  PdfServiceO._internal();

  // Font cache
  pw.Font? _arabicFont;
  pw.MemoryImage? _logoImage;

  // Initialize resources
  Future<void> _initResources() async {
    if (_arabicFont == null) {
      final fontData =
          await rootBundle.load('assets/fonts/AL-Mohanad-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
    }

    if (_logoImage == null) {
      final logoData =
          await rootBundle.load('assets/images/logo_generators.png');
      final logoBytes = logoData.buffer.asUint8List();
      _logoImage = pw.MemoryImage(logoBytes);
    }
  }

  // Generate PDF for date range report
  Future<File> generateDateRangeReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<BaseConsumption> generators,
    required double totalConsumption,
    required double totalSolarConsumption,
    required double totalGeneratorConsumption,
    required double totalDiesel,
  }) async {
    await _initResources();

    final pdf = pw.Document();

    // Add page with Arabic text direction
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont!,
        ),
        build: (pw.Context context) => [
          _buildHeader(
            title: 'تقرير بين التواريخ',
            startDate: startDate,
            endDate: endDate,
          ),
          pw.SizedBox(height: 20),
          _buildSummarySection(
            totalConsumption: totalConsumption,
            totalSolarConsumption: totalSolarConsumption,
            totalGeneratorConsumption: totalGeneratorConsumption,
            totalDiesel: totalDiesel,
          ),
          pw.SizedBox(height: 20),
          _buildGeneratorsSection(generators),
        ],
      ),
    );

    // Save the PDF
    return _savePdf(
        'تقرير_${DateFormat('yyyy_MM_dd').format(startDate)}_${DateFormat('yyyy_MM_dd').format(endDate)}.pdf',
        pdf);
  }

  // Generate PDF for solar system analysis
  Future<File> generateSolarAnalysisReport({
    required SolarSystem solarSystem,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> detailedReadings,
  }) async {
    await _initResources();

    final pdf = pw.Document();

    // Add page with Arabic text direction
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont!,
        ),
        build: (pw.Context context) => [
          _buildHeader(
            title: 'تحليل المنظومة الشمسية: ${solarSystem.name}',
            startDate: startDate,
            endDate: endDate,
          ),
          pw.SizedBox(height: 20),
          _buildSolarSummarySection(summary),
          pw.SizedBox(height: 20),
          _buildSolarReadingsSection(detailedReadings),
        ],
      ),
    );

    // Save the PDF
    return _savePdf(
        'تحليل_منظومة_${solarSystem.name}_${DateFormat('yyyy_MM_dd').format(startDate)}.pdf',
        pdf);
  }

  // Generate PDF for generator analysis
  Future<File> generateGeneratorAnalysisReport({
    required Generator generator,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> detailedReadings,
  }) async {
    await _initResources();

    final pdf = pw.Document();

    // Add page with Arabic text direction
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _arabicFont!,
        ),
        build: (pw.Context context) => [
          _buildHeader(
            title: 'تحليل المولد: ${generator.name}',
            startDate: startDate,
            endDate: endDate,
          ),
          pw.SizedBox(height: 20),
          _buildGeneratorSummarySection(summary),
          pw.SizedBox(height: 20),
          _buildGeneratorReadingsSection(detailedReadings),
        ],
      ),
    );

    // Save the PDF
    return _savePdf(
        'تحليل_مولد_${generator.name}_${DateFormat('yyyy_MM_dd').format(startDate)}.pdf',
        pdf);
  }

  // Build header with logo and title
  pw.Widget _buildHeader({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Image(_logoImage!, width: 60, height: 60),
            pw.SizedBox(width: 10),
            pw.Text(
              'نظام متابعة استهلاك الكهرباء',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'الفترة من ${DateFormat('yyyy-MM-dd').format(startDate)} إلى ${DateFormat('yyyy-MM-dd').format(endDate)}',
          style: pw.TextStyle(
            fontSize: 14,
          ),
        ),
        pw.Divider(),
      ],
    );
  }

  // Build summary section for date range report
  pw.Widget _buildSummarySection({
    required double totalConsumption,
    required double totalSolarConsumption,
    required double totalGeneratorConsumption,
    required double totalDiesel,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الانتاج',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildSummaryRow(
              label: 'مجموع الانتاج',
              value: '${totalConsumption.toStringAsFixed(2)} KWh',
              color: PdfColors.green),
          _buildSummaryRow(
            label: 'إنتاج المولدات',
            value: '${totalGeneratorConsumption.toStringAsFixed(2)} kWh',
            color: PdfColors.orange,
          ),
          _buildSummaryRow(
            label: 'إنتاج المنظومات',
            value: '${totalSolarConsumption.toStringAsFixed(2)} kWh',
            color: PdfColors.blue,
          ),
          _buildSummaryRow(
            label: 'مجموع استهلاك الديزل',
            value: '${totalDiesel.toStringAsFixed(2)} L',
            color: PdfColors.red,
          ),
        ],
      ),
    );
  }

  // Build generators section for date range report
  pw.Widget _buildGeneratorsSection(List<BaseConsumption> generators) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل المولدات والمنظومات',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...generators.map((gen) => _buildConsumptionCard(gen)).toList(),
      ],
    );
  }

  // Build consumption card for generators and solar systems
  pw.Widget _buildConsumptionCard(BaseConsumption gen) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            gen.generatorName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          if (gen is GeneratorConsumption) ...[
            _buildDetailRow(
                'القراءة الأولى', '${gen.startReading.toStringAsFixed(2)} kWh'),
            _buildDetailRow(
                'القراءة الأخيرة', '${gen.endReading.toStringAsFixed(2)} kWh'),
            _buildDetailRow('إجمالي الانتاج',
                '${gen.totalConsumption.toStringAsFixed(2)} kWh'),
            _buildDetailRow(
                'إجمالي الديزل', '${gen.totalDiesel.toStringAsFixed(2)} لتر'),
          ] else ...[
            _buildDetailRow('إجمالي الإنتاج',
                '${gen.totalConsumption.toStringAsFixed(2)} kWh'),
          ],
        ],
      ),
    );
  }

  // Build solar summary section
  pw.Widget _buildSolarSummarySection(Map<String, dynamic> summary) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildSummaryRow(
            label: 'اجمالي انتاج الكيلوهات',
            value:
                '${summary['totalMeterReading']?.toStringAsFixed(2) ?? '0.00'} kWh',
            color: PdfColors.orange,
          ),
          _buildSummaryRow(
            label: 'عدد الأيام',
            value: '${summary['days'] ?? '0'} يوم',
            color: PdfColors.green,
          ),
        ],
      ),
    );
  }

  // Build solar readings section
  pw.Widget _buildSolarReadingsSection(
      List<Map<String, dynamic>> detailedReadings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل القراءات',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...detailedReadings.map((reading) {
          final readingObj = reading['readingObj'] as Reading;
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
              color: PdfColors.orange50,
            ),
            padding: pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      reading['name'] ?? 'منظومة شمسية',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(reading['date'] ?? ''),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('القراءة : الاستهلاك'),
                    pw.Text(
                        '${readingObj.meterReading.toStringAsFixed(2)} kWh'),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build generator summary section
  pw.Widget _buildGeneratorSummarySection(Map<String, dynamic> summary) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildSummaryRow(
            label: 'الاستهلاك الكلي',
            value:
                '${summary['totalConsumption']?.toStringAsFixed(2) ?? '0.00'} kWh',
            color: PdfColors.red,
          ),
          _buildSummaryRow(
            label: 'استهلاك الديزل',
            value: '${summary['totalDiesel']?.toStringAsFixed(2) ?? '0.00'} L',
            color: PdfColors.orange,
          ),
          _buildSummaryRow(
            label: 'متوسط معدل الديزل',
            value: '${summary['avgRate']?.toStringAsFixed(2) ?? '0.00'} kWh/L',
            color: PdfColors.blue,
          ),
          _buildSummaryRow(
            label: 'عدد الأيام',
            value: '${summary['days'] ?? '0'} يوم',
            color: PdfColors.green,
          ),
        ],
      ),
    );
  }

  // Build generator readings section
  pw.Widget _buildGeneratorReadingsSection(
      List<Map<String, dynamic>> detailedReadings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل القراءات',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...detailedReadings.map((reading) {
          final readingObj = reading['readingObj'] as Reading;
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
              color: PdfColors.orange50,
            ),
            padding: pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      reading['name'] ?? 'مولد',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(reading['date'] ?? ''),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('القراءة:'),
                    pw.Text(
                        '${readingObj.meterReading.toStringAsFixed(2)} kWh'),
                  ],
                ),
                if (readingObj.dieselConsumption != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('استهلاك الديزل:'),
                      pw.Text(
                          '${readingObj.dieselConsumption!.toStringAsFixed(2)} L'),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('معدل الاستهلاك:'),
                      pw.Text(
                          '${reading['dieselRate']?.toStringAsFixed(2) ?? 'N/A'} L/kWh'),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build summary row with color
  pw.Widget _buildSummaryRow({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Build detail row
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value),
        ],
      ),
    );
  }

  // Save PDF to file
  Future<File> _savePdf(String fileName, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Share PDF file
  Future<void> sharePdf(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'تقرير استهلاك الكهرباء',
    );
  }
}
