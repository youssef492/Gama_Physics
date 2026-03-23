import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_user.dart';

class StudentsPdfService {
  static Future<pw.MemoryImage> _generateQrImage(String data) async {
    const double size = 200;

    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    qrPainter.paint(canvas, const ui.Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(byteData!.buffer.asUint8List());
  }

  // ── حفظ في Downloads ──────────────────────────────────────────────────────
  static Future<String> _savePdf({
    required List<int> bytes,
    required String filterLabel,
  }) async {
    final timestamp =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}';
    final safeName = filterLabel.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    final fileName = 'gama_students_${safeName}_$timestamp.pdf';

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

  // ── Main entry point ──────────────────────────────────────────────────────
  static Future<void> generateAndShare({
    required List<AppUser> students,
    required String filterLabel,
    required Map<String, int> stageStats,
    required bool isArabic,
  }) async {
    if (students.isEmpty) return;

    final Map<String, pw.MemoryImage> qrImages = {};
    for (final student in students) {
      qrImages[student.uid] = await _generateQrImage(student.uid);
    }

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final pdf = pw.Document();

    const cardsPerPage = 6;
    for (int pageStart = 0;
        pageStart < students.length;
        pageStart += cardsPerPage) {
      final pageStudents = students.sublist(
        pageStart,
        (pageStart + cardsPerPage).clamp(0, students.length),
      );
      final isFirstPage = pageStart == 0;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                if (isFirstPage) ...[
                  _buildHeader(
                      isArabic: isArabic,
                      filterLabel: filterLabel,
                      ttf: ttf,
                      ttfBold: ttfBold),
                  pw.SizedBox(height: 10),
                  _buildStats(
                      stageStats: stageStats,
                      isArabic: isArabic,
                      ttf: ttf,
                      ttfBold: ttfBold),
                  pw.SizedBox(height: 14),
                ],
                pw.Expanded(
                  child: _buildCardsGrid(
                    pageStudents: pageStudents,
                    qrImages: qrImages,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.Text(
                  'Gama Physics © ${DateTime.now().year}',
                  style: pw.TextStyle(
                      font: ttf, fontSize: 9, color: PdfColors.grey500),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );
    }

    // ── حفظ في Downloads مباشرةً بدون share ──────────────────────────────
    final bytes = await pdf.save();
    await _savePdf(bytes: bytes, filterLabel: filterLabel);
  }

  // ── Header ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader({
    required bool isArabic,
    required String filterLabel,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('1A3A5C'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gama Physics',
            style: pw.TextStyle(
                font: ttfBold, fontSize: 18, color: PdfColors.white),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                isArabic ? 'كشف الطلاب' : 'Students List',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 13, color: PdfColors.white),
              ),
              pw.Text(
                filterLabel,
                style: pw.TextStyle(
                    font: ttf,
                    fontSize: 10,
                    color: PdfColor.fromHex("B3FFFFFF")),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  static pw.Widget _buildStats({
    required Map<String, int> stageStats,
    required bool isArabic,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    return pw.Row(
      children: stageStats.entries.map((entry) {
        return pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(left: 6),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('EEF2FF'),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: PdfColor.fromHex('0D6EBE'),
                width: 1.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  '${entry.value}',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 22,
                    color: PdfColor.fromHex('0D6EBE'),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                      font: ttf, fontSize: 9, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Cards Grid ────────────────────────────────────────────────────────────
  static pw.Widget _buildCardsGrid({
    required List<AppUser> pageStudents,
    required Map<String, pw.MemoryImage> qrImages,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < pageStudents.length; i += 2) {
      final s1 = pageStudents[i];
      final s2 = i + 1 < pageStudents.length ? pageStudents[i + 1] : null;

      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildStudentCard(
                student: s1,
                qrImage: qrImages[s1.uid]!,
                ttf: ttf,
                ttfBold: ttfBold,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: s2 != null
                  ? _buildStudentCard(
                      student: s2,
                      qrImage: qrImages[s2.uid]!,
                      ttf: ttf,
                      ttfBold: ttfBold,
                    )
                  : pw.Container(),
            ),
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 10));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  // ── Student Card ──────────────────────────────────────────────────────────
  static pw.Widget _buildStudentCard({
    required AppUser student,
    required pw.MemoryImage qrImage,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    final displayCode = student.studentCode.isNotEmpty
        ? student.studentCode
        : student.uid.substring(0, 8).toUpperCase();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey200),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Image(qrImage, width: 75, height: 75),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  student.name,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 12,
                    color: PdfColor.fromHex('1A1A2E'),
                  ),
                  maxLines: 1,
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('DBEAFE'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    student.grade,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: PdfColor.fromHex('1D4ED8')),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(left: 4),
                      child: pw.Text(
                        'Tel: ',
                        style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 9,
                            color: PdfColors.grey600),
                      ),
                    ),
                    pw.Text(
                      student.phone,
                      style: pw.TextStyle(
                          font: ttf, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1A3A5C'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    displayCode,
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 11,
                      color: PdfColors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
