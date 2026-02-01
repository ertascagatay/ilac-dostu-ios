import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/medication_log.dart';
import '../models/measurement_model.dart';

class PdfService {
  static Future<File> generateDoctorReport({
    required String patientName,
    required String patientUid,
    required List<MedicationLog> medicationLogs,
    required List<MeasurementModel> measurements,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // Calculate adherence rate
    final totalMeds = medicationLogs.length;
    final adherenceRate = totalMeds > 0 ? 100 : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HASTA SAĞLIK RAPORU',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'İlaç Dostu - Health Suite v3.0',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Patient Info
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Hasta Adı:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(patientName, style: const pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Hasta Kodu:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(patientUid, style: const pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Rapor Dönemi:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${dateFormat.format(start)} - ${dateFormat.format(end)}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Oluşturulma:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(dateFormat.format(DateTime.now())),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Medication Adherence Section
          pw.Header(
            level: 1,
            text: 'İLAÇ UYUM RAPORU',
          ),

          pw.SizedBox(height: 12),

          if (medicationLogs.isEmpty)
            pw.Text('Bu dönemde ilaç alım kaydı bulunmamaktadır.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('İlaç Adı', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Tarih/Saat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Kalan Stok', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Data rows
                ...medicationLogs.take(20).map((log) {
                  final dateTimeFormat = DateFormat('dd/MM HH:mm', 'tr_TR');
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(log.medicationName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(dateTimeFormat.format(log.takenAt)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${log.stockAfter} adet'),
                      ),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 16),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Toplam İlaç Alımı: $totalMeds',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 24),

          // Vital Signs Section
          pw.Header(
            level: 1,
            text: 'YAŞAMSAL BULGULAR GEÇMİŞİ',
          ),

          pw.SizedBox(height: 12),

          if (measurements.isEmpty)
            pw.Text('Bu dönemde yaşamsal bulgu kaydı bulunmamaktadır.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Tarih', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Ölçüm Tipi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Değer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Data rows
                ...measurements.take(30).map((measurement) {
                  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'tr_TR');
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(dateFormat.format(measurement.timestamp)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(measurement.typeDisplayName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(measurement.displayValue),
                      ),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),

          // Summary Section
          pw.Header(
            level: 1,
            text: 'ÖZET',
          ),

          pw.SizedBox(height: 12),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• Toplam İlaç Alımı: $totalMeds'),
                pw.SizedBox(height: 8),
                pw.Text('• Toplam Yaşamsal Bulgu Kaydı: ${measurements.length}'),
                pw.SizedBox(height: 8),
                if (measurements.isNotEmpty) ...[
                  pw.Text('• Son Ölçümler:'),
                  pw.SizedBox(height: 4),
                  ...measurements.take(5).map((m) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, top: 4),
                    child: pw.Text('  - ${m.typeDisplayName}: ${m.displayValue}'),
                  )),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 32),

          // Footer
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Bu rapor İlaç Dostu Health Suite v3.0 tarafından otomatik olarak oluşturulmuştur.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'Doktorunuza danışmadan ilaç kullanmayınız.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share the PDF report
  static Future<void> shareReport(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: 'health_report.pdf',
    );
  }

  /// Print or preview the PDF report
  static Future<void> printReport(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }
}
