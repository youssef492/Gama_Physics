import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';

class StudentsExcelService {
  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _headerBg = 'FF1A3A5C';
  static const _rowAlt = 'FFF0F4F8';
  static const _rowNormal = 'FFFFFFFF';
  static const _accentBlue = 'FF0D6EBE';
  static const _disabledBg = 'FFFDE8E8';
  static const _disabledFg = 'FFE74C3C';

  static Future<String> exportStudents({
    required List<AppUser> students,
    required Map<String, int> stageStats,
    required String filterLabel,
    required bool isArabic,
  }) async {
    final excel = Excel.createExcel();

    // ─── Sheet 1: Students list ──────────────────────────────────────────
    final listSheetName = isArabic ? 'بيانات الطلاب' : 'Students';
    excel.rename('Sheet1', listSheetName);
    final listSheet = excel[listSheetName];

    _buildStudentsSheet(
      sheet: listSheet,
      students: students,
      filterLabel: filterLabel,
      isArabic: isArabic,
    );

    // ─── Sheet 2: Summary by stage ───────────────────────────────────────
    final summarySheetName = isArabic ? 'ملخص المراحل' : 'Summary';
    final summarySheet = excel[summarySheetName];

    _buildSummarySheet(
      sheet: summarySheet,
      stageStats: stageStats,
      isArabic: isArabic,
    );

    // ─── Save ─────────────────────────────────────────────────────────────
    final bytes = excel.encode()!;
    final dir = await _getSaveDirectory();
    final timestamp = _formattedDate();
    final file = File('${dir.path}/gama_students_$timestamp.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ─── Sheet 1: Students ───────────────────────────────────────────────────
  static void _buildStudentsSheet({
    required Sheet sheet,
    required List<AppUser> students,
    required String filterLabel,
    required bool isArabic,
  }) {
    final headers = isArabic
        ? [
            'م',
            'الاسم',
            'رقم الهاتف',
            'المرحلة',
            'كود الطالب',
            'تاريخ التسجيل',
            'الحالة'
          ]
        : [
            '#',
            'Name',
            'Phone',
            'Stage',
            'Student Code',
            'Registration Date',
            'Status'
          ];

    // Row 0: Title
    _write(sheet, 0, 0,
        value: isArabic
            ? 'كشف الطلاب - Gama Physics'
            : 'Students List - Gama Physics',
        bold: true,
        fontSize: 14,
        fontColor: 'FF1A3A5C');

    // Row 1: filter label + date
    _write(sheet, 1, 0,
        value: '$filterLabel  |  ${_formattedDateReadable()}',
        fontSize: 9,
        fontColor: 'FF5D6D7E');

    // Row 2: total count
    _write(sheet, 2, 0,
        value: isArabic
            ? 'إجمالي الطلاب: ${students.length}'
            : 'Total Students: ${students.length}',
        fontSize: 10,
        bold: true,
        fontColor: _accentBlue);

    // Row 4: Headers
    for (int c = 0; c < headers.length; c++) {
      _write(sheet, 4, c,
          value: headers[c],
          bold: true,
          fontColor: 'FFFFFFFF',
          bgColor: _headerBg,
          align: HorizontalAlign.Center,
          fontSize: 11);
    }

    // Rows 5+: Data
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final rowIdx = i + 5;
      final bg = i.isEven ? _rowAlt : _rowNormal;
      final isDisabled = s.isDisabled;

      final statusLabel = isDisabled
          ? (isArabic ? 'معطل' : 'Disabled')
          : (isArabic ? 'نشط' : 'Active');
      final statusBg = isDisabled ? _disabledBg : 'FFE8F5E9';
      final statusFg = isDisabled ? _disabledFg : 'FF27AE60';

      final regDate =
          '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}';
      final code = s.studentCode.isNotEmpty ? s.studentCode : '—';

      _write(sheet, rowIdx, 0,
          value: '${i + 1}',
          bgColor: bg,
          align: HorizontalAlign.Center,
          fontSize: 10);
      _write(sheet, rowIdx, 1,
          value: s.name, bold: true, bgColor: bg, fontSize: 11);
      _write(sheet, rowIdx, 2,
          value: s.phone,
          bgColor: bg,
          align: HorizontalAlign.Left,
          fontSize: 10);
      _write(sheet, rowIdx, 3, value: s.grade, bgColor: bg, fontSize: 10);
      _write(sheet, rowIdx, 4,
          value: code,
          bold: true,
          fontColor: _accentBlue,
          bgColor: bg,
          align: HorizontalAlign.Center,
          fontSize: 11);
      _write(sheet, rowIdx, 5,
          value: regDate,
          bgColor: bg,
          align: HorizontalAlign.Center,
          fontSize: 10);
      _write(sheet, rowIdx, 6,
          value: statusLabel,
          bold: true,
          fontColor: statusFg,
          bgColor: statusBg,
          align: HorizontalAlign.Center,
          fontSize: 10);
    }

    // Column widths
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 12);
  }

  // ─── Sheet 2: Summary ────────────────────────────────────────────────────
  static void _buildSummarySheet({
    required Sheet sheet,
    required Map<String, int> stageStats,
    required bool isArabic,
  }) {
    // Title
    _write(sheet, 0, 0,
        value: isArabic ? 'ملخص المراحل الدراسية' : 'Stage Summary',
        bold: true,
        fontSize: 14,
        fontColor: 'FF1A3A5C');

    // Headers
    _write(sheet, 2, 0,
        value: isArabic ? 'المرحلة' : 'Stage',
        bold: true,
        fontColor: 'FFFFFFFF',
        bgColor: _headerBg,
        align: HorizontalAlign.Center);
    _write(sheet, 2, 1,
        value: isArabic ? 'عدد الطلاب' : 'Count',
        bold: true,
        fontColor: 'FFFFFFFF',
        bgColor: _headerBg,
        align: HorizontalAlign.Center);
    _write(sheet, 2, 2,
        value: isArabic ? 'النسبة' : 'Percentage',
        bold: true,
        fontColor: 'FFFFFFFF',
        bgColor: _headerBg,
        align: HorizontalAlign.Center);

    final entries = stageStats.entries.toList();
    // Total is first entry
    final total = entries.isNotEmpty ? (entries.first.value) : 0;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final rowIdx = i + 3;
      final bg = i.isEven ? _rowAlt : _rowNormal;
      final isTotal = i == 0;

      final percentage = total > 0 && !isTotal
          ? '${((entry.value / total) * 100).toStringAsFixed(1)}%'
          : (isTotal ? '100%' : '—');

      _write(sheet, rowIdx, 0,
          value: entry.key,
          bold: isTotal,
          bgColor: isTotal ? _headerBg : bg,
          fontColor: isTotal ? 'FFFFFFFF' : 'FF1A1A2E');
      _write(sheet, rowIdx, 1,
          value: '${entry.value}',
          bold: isTotal,
          bgColor: isTotal ? _headerBg : bg,
          fontColor: isTotal ? 'FFFFFFFF' : _accentBlue,
          align: HorizontalAlign.Center,
          fontSize: isTotal ? 13 : 11);
      _write(sheet, rowIdx, 2,
          value: percentage,
          bgColor: isTotal ? _headerBg : bg,
          fontColor: isTotal ? 'FFFFFFFF' : 'FF5D6D7E',
          align: HorizontalAlign.Center);
    }

    sheet.setColumnWidth(0, 26);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 14);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  static String _formattedDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static String _formattedDateReadable() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ─── Export success dialog ────────────────────────────────────────────────────

class StudentsExportSuccessDialog extends StatelessWidget {
  final String filePath;
  final bool isArabic;

  const StudentsExportSuccessDialog({
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
                    const Icon(Icons.table_chart,
                        size: 16, color: Color(0xFF1A3A5C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dirPath,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
