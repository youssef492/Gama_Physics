import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/access_code.dart';

class ExcelExportService {
  // ─── Colors (ARGB) ────────────────────────────────
  static const _headerBg = 'FF1A3A5C';
  static const _rowAlt = 'FFF0F4F8';
  static const _rowNormal = 'FFFFFFFF';

  static const _statusColors = <String, (String, String)>{
    'active': ('FFE8F5E9', 'FF27AE60'),
    'used': ('FFFFF3E0', 'FFE67E22'),
    'expired': ('FFFFEBEE', 'FFE74C3C'),
    'disabled': ('FFF5F5F5', 'FF757575'),
  };

  static const _statusLabelsAr = <String, String>{
    'active': 'فعال',
    'used': 'مستخدم',
    'expired': 'منتهي',
    'disabled': 'معطل',
  };

  static const _statusLabelsEn = <String, String>{
    'active': 'Active',
    'used': 'Used',
    'expired': 'Expired',
    'disabled': 'Disabled',
  };

  /// يصدر الأكواد لـ xlsx ويحفظها — يرجع مسار الملف
  static Future<String> exportCodes({
    required List<AccessCode> codes,
    required Map<String, String> lessonTitles,
    bool isArabic = true,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = isArabic ? 'أكواد الوصول' : 'Access Codes';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final headers = isArabic
        ? [
            'الكود',
            'اسم الدرس',
            'الحالة',
            'الاستخدام',
            'تاريخ الانتهاء',
            'المستخدمون'
          ]
        : ['Code', 'Lesson', 'Status', 'Usage', 'Expires', 'Used By'];

    final statusLabels = isArabic ? _statusLabelsAr : _statusLabelsEn;

    // Row 0: Title
    _write(
      sheet,
      0,
      0,
      value: isArabic
          ? 'تقرير أكواد الوصول - Gama Physics'
          : 'Access Codes Report - Gama Physics',
      bold: true,
      fontSize: 14,
      fontColor: 'FF1A3A5C',
    );

    // Row 1: Count
    _write(
      sheet,
      1,
      0,
      value: isArabic
          ? 'إجمالي الأكواد: ${codes.length}'
          : 'Total Codes: ${codes.length}',
      fontSize: 9,
      fontColor: 'FF5D6D7E',
    );

    // Row 2: Headers
    for (int c = 0; c < headers.length; c++) {
      _write(
        sheet,
        2,
        c,
        value: headers[c],
        bold: true,
        fontColor: 'FFFFFFFF',
        bgColor: _headerBg,
        align: HorizontalAlign.Center,
      );
    }

    // Rows 3+: Data
    for (int i = 0; i < codes.length; i++) {
      final code = codes[i];
      final rowIdx = i + 3;
      final bg = i.isEven ? _rowAlt : _rowNormal;
      final (sBg, sFg) = _statusColors[code.status] ?? ('FFF5F5F5', 'FF757575');

      final expiry = code.expiresAt != null
          ? '${code.expiresAt!.day}/${code.expiresAt!.month}/${code.expiresAt!.year}'
          : (isArabic ? 'بلا تاريخ' : 'No expiry');
      final usedBy = code.usedBy.isEmpty
          ? '—'
          : code.usedBy
              .map((u) =>
                  '${u.studentName} - ${u.usedAt.day}/${u.usedAt.month}/${u.usedAt.year}')
              .join(' | ');

      _write(sheet, rowIdx, 0,
          value: code.code, bold: true, fontColor: 'FF1A3A5C', bgColor: bg);
      _write(sheet, rowIdx, 1,
          value: lessonTitles[code.lessonId] ?? '...', bgColor: bg);
      _write(sheet, rowIdx, 2,
          value: statusLabels[code.status] ?? code.status,
          bold: true,
          fontColor: sFg,
          bgColor: sBg,
          align: HorizontalAlign.Center);
      _write(sheet, rowIdx, 3,
          value: '${code.currentUses}/${code.maxUses}',
          bgColor: bg,
          align: HorizontalAlign.Center);
      _write(sheet, rowIdx, 4,
          value: expiry, bgColor: bg, align: HorizontalAlign.Center);
      _write(sheet, rowIdx, 5, value: usedBy, bgColor: bg);
    }

    // Summary
    final summaryStart = codes.length + 4;
    _write(
      sheet,
      summaryStart,
      0,
      value: isArabic ? 'الملخص' : 'Summary',
      bold: true,
      fontColor: 'FFFFFFFF',
      bgColor: _headerBg,
      align: HorizontalAlign.Center,
    );
    const statuses = ['active', 'used', 'expired', 'disabled'];
    for (int j = 0; j < statuses.length; j++) {
      final s = statuses[j];
      final (sBg, sFg) = _statusColors[s]!;
      _write(sheet, summaryStart + 1 + j, 0,
          value: statusLabels[s]!,
          bold: true,
          fontColor: sFg,
          bgColor: sBg,
          align: HorizontalAlign.Center);
      _write(sheet, summaryStart + 1 + j, 1,
          value: '${codes.where((c) => c.status == s).length}',
          bold: true,
          fontColor: sFg,
          bgColor: sBg,
          align: HorizontalAlign.Center);
    }

    // Column widths
    sheet.setColumnWidth(0, 16);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 44);

    // ─── Save file ────────────────────────────────
    final bytes = excel.encode()!;
    final dir = await _getSaveDirectory();
    final timestamp = _formattedDate();
    final file = File('${dir.path}/gama_codes_$timestamp.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Android → Downloads أو External Storage, iOS → Documents
  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Download — بيبان في Files app
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      // Fallback
      return await getApplicationDocumentsDirectory();
    }
    // iOS → Documents (accessible via Files app)
    return await getApplicationDocumentsDirectory();
  }

  static String _formattedDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  // ─── Helper ───────────────────────────────────────
  static void _write(
    Sheet sheet,
    int row,
    int col, {
    required String value,
    bool bold = false,
    String fontColor = 'FF000000',
    String? bgColor,
    double fontSize = 10,
    HorizontalAlign align = HorizontalAlign.Right,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontFamily: 'Arial',
      fontColorHex: ExcelColor.fromHexString(fontColor),
      backgroundColorHex:
          bgColor != null ? ExcelColor.fromHexString(bgColor) : ExcelColor.none,
      horizontalAlign: align,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
  }
}

/// Dialog بيتبين بعد الـ export فيه مسار الملف
class ExportSuccessDialog extends StatelessWidget {
  final String filePath;
  final bool isArabic;

  const ExportSuccessDialog({
    super.key,
    required this.filePath,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split('/').last;
    final dirPath = filePath.substring(0, filePath.lastIndexOf('/'));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: Color(0xFF27AE60), size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'تم التصدير بنجاح!' : 'Export Successful!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file,
                        size: 16, color: Color(0xFF1A3A5C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dirPath,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'الملف محفوظ في Downloads\nافتحه من تطبيق Files'
                : 'File saved to Downloads\nOpen it from the Files app',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'حسناً' : 'OK'),
        ),
      ],
    );
  }
}
