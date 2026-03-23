import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_session.dart';

class PdfService {
  static Future<void> generateAndShareSessionPdf(
      AttendanceSession session, double totalCollected) async {
    final pdf = pw.Document();

    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      final ttfBold = pw.Font.ttf(boldFontData);

      final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm a');
      final formattedDate = formatter.format(session.date);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttfBold,
          ),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1A3A5C'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Gama Physics',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 22,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'تقرير الحضور',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 14,
                          color: PdfColor.fromHex('B3FFFFFF'),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // ── Info Box ─────────────────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F0F4F8'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('0D6EBE'),
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        label: 'اسم الحصة',
                        value:
                            session.title.isEmpty ? 'بدون اسم' : session.title,
                        ttf: ttf,
                        ttfBold: ttfBold,
                      ),
                      pw.SizedBox(height: 6),
                      _infoRow(
                        label: 'التاريخ',
                        value: formattedDate,
                        ttf: ttf,
                        ttfBold: ttfBold,
                      ),
                      pw.SizedBox(height: 6),
                      _infoRow(
                        label: 'عدد الطلاب',
                        value: '${session.presentStudents.length}',
                        ttf: ttf,
                        ttfBold: ttfBold,
                      ),
                      pw.SizedBox(height: 6),
                      _infoRow(
                        label: 'إجمالي المحصل',
                        value: '$totalCollected ج.م',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        highlight: true,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // ── Table ────────────────────────────────────────────────
                pw.TableHelper.fromTextArray(
                  headers: ['م', 'الاسم', 'رقم الهاتف', 'المرحلة', 'المدفوع'],
                  data: session.presentStudents
                      .asMap()
                      .entries
                      .map((e) => [
                            '${e.key + 1}',
                            e.value['name'] ?? 'بدون اسم',
                            e.value['phone'] ?? '-',
                            e.value['grade'] ?? '-',
                            '${e.value['paidAmount'] ?? 0.0} ج.م',
                          ])
                      .toList(),
                  headerStyle: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1A3A5C'),
                  ),
                  cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                  cellAlignment: pw.Alignment.centerRight,
                  border: pw.TableBorder.all(
                    color: PdfColor.fromHex('DDDDDD'),
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(24),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(2.5),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                ),

                pw.Spacer(),

                // ── Footer ───────────────────────────────────────────────
                pw.Divider(color: PdfColors.grey300),
                pw.Text(
                  'Gama Physics © ${DateTime.now().year}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // ── حفظ في Downloads ────────────────────────────────────────────────
      final bytes = await pdf.save();
      final filePath = await _savePdfToDownloads(
        bytes: bytes,
        session: session,
      );

      // ── Share بعد الحفظ ─────────────────────────────────────────────────
      await Printing.sharePdf(
        bytes: bytes,
        filename: filePath.split('/').last,
      );
    } catch (e) {
      debugPrint("Error generating PDF: $e");
    }
  }

  // ── Helper: حفظ في Downloads ─────────────────────────────────────────────
  static Future<String> _savePdfToDownloads({
    required List<int> bytes,
    required AttendanceSession session,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(session.date);
    final fileName = 'attendance_$timestamp.pdf';

    Directory dir;
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      dir = await downloads.exists()
          ? downloads
          : await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    debugPrint('PDF saved to: ${file.path}');
    return file.path;
  }

  // ── Helper: info row ─────────────────────────────────────────────────────
  static pw.Widget _infoRow({
    required String label,
    required String value,
    required pw.Font ttf,
    required pw.Font ttfBold,
    bool highlight = false,
  }) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: 11,
            color: PdfColor.fromHex('1A3A5C'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 11,
            color: highlight ? PdfColor.fromHex('27AE60') : PdfColors.grey800,
            fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
