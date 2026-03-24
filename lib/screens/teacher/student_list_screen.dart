
import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/services/student_excel_service.dart';
import 'package:gama/services/student_pdf_secvice.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/app_user.dart';
import '../../models/access_code.dart';


class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  String? _selectedStage; // null = All
  bool _isExporting = false;
  bool _isExcelExporting = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<DataProvider>();
    data.listenToStudents();
    data.listenToStages();
  }

  // ─── Filtered students ───────────────────────────────────────────────────
  List<AppUser> _filteredStudents(DataProvider data) {
    return data.students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.phone.contains(_searchQuery) ||
          s.studentCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStage = _selectedStage == null || s.grade == _selectedStage;
      return matchesSearch && matchesStage;
    }).toList();
  }

  // ─── Stage stats for analytics ───────────────────────────────────────────
  Map<String, int> _buildStageStats(DataProvider data) {
    final stats = <String, int>{};
    final l10n = AppLocalizations.of(context)!;
    stats[l10n.students] = data.students.length; // Total
    for (final stage in data.stages) {
      stats[stage.name] =
          data.students.where((s) => s.grade == stage.name).length;
    }
    return stats;
  }

  // ─── PDF export ──────────────────────────────────────────────────────────
  Future<void> _exportPdf(DataProvider data) async {
    final filtered = _filteredStudents(data);
    if (filtered.isEmpty) return;

    setState(() => _isExporting = true);
    try {
      final isArabic = context.read<LanguageProvider>().isArabic;
      final stageStats = _buildStageStats(data);
      final label = _selectedStage ?? (AppLocalizations.of(context)!.students);

      await StudentsPdfService.generateAndShare(
        students: filtered,
        filterLabel: label,
        stageStats: stageStats,
        isArabic: isArabic,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ─── Excel export ────────────────────────────────────────────────────────
  Future<void> _exportExcel(DataProvider data) async {
    final filtered = _filteredStudents(data);
    if (filtered.isEmpty) return;

    setState(() => _isExcelExporting = true);
    try {
      final isArabic = context.read<LanguageProvider>().isArabic;
      final stageStats = _buildStageStats(data);
      final label = _selectedStage ?? AppLocalizations.of(context)!.students;

      final filePath = await StudentsExcelService.exportStudents(
        students: filtered,
        stageStats: stageStats,
        filterLabel: label,
        isArabic: isArabic,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => StudentsExportSuccessDialog(
            filePath: filePath,
            isArabic: isArabic,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExcelExporting = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final filtered = _filteredStudents(data);
    final stageStats = _buildStageStats(data);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageStudents),
        actions: [
          // Excel export button
          _isExcelExporting
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.table_chart_outlined),
                  tooltip: l10n.exportExcel,
                  onPressed: () => _exportExcel(data),
                ),
          // PDF export button
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: l10n.exportPdf,
                  onPressed: () => _exportPdf(data),
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Analytics Cards ─────────────────────────────────────────────
          _AnalyticsSection(stageStats: stageStats),

          // ── Stage Filter Chips ───────────────────────────────────────────
          _StageFilterChips(
            stages: data.stages.map((s) => s.name).toList(),
            selected: _selectedStage,
            onSelected: (stage) => setState(() => _selectedStage = stage),
          ),

          // ── Search Field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchStudents,
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Count + Export hint ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${l10n.studentCount}: ${filtered.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
                const Spacer(),
                if (filtered.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isExporting ? null : () => _exportPdf(data),
                    icon: const Icon(Icons.print,
                        size: 16, color: AppTheme.primaryBlue),
                    label: Text(
                      _selectedStage != null
                          ? '${l10n.exportPdf} $_selectedStage'
                          : '${l10n.exportPdf} ${l10n.all}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),

          // ── Students List ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(l10n.noStudents,
                        style: const TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return _StudentCard(
                        student: student,
                        data: data,
                        onDelete: () => _confirmDelete(context, data, student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Delete dialog ───────────────────────────────────────────────────────
  void _confirmDelete(
      BuildContext context, DataProvider data, AppUser student) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.deleteStudentConfirm} "${student.name}"؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteWarning,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await data.deleteStudent(student.uid);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.deletedSuccess)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(l10n.deleteBtn),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics Section
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsSection extends StatelessWidget {
  final Map<String, int> stageStats;

  const _AnalyticsSection({required this.stageStats});

  @override
  Widget build(BuildContext context) {
    if (stageStats.isEmpty) return const SizedBox.shrink();

    final entries = stageStats.entries.toList();

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final isTotal = index == 0;
          final entry = entries[index];
          return Container(
            width: 108,
            margin: const EdgeInsetsDirectional.only(end: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTotal
                    ? [AppTheme.deepNavy, AppTheme.darkBlue]
                    : [
                        AppTheme.primaryBlue.withAlpha(20),
                        AppTheme.primaryBlue.withAlpha(10),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: isTotal
                  ? null
                  : Border.all(color: AppTheme.primaryBlue.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isTotal ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 10,
                    color: isTotal ? Colors.white70 : AppTheme.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage Filter Chips
// ─────────────────────────────────────────────────────────────────────────────

class _StageFilterChips extends StatelessWidget {
  final List<String> stages;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _StageFilterChips({
    required this.stages,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (stages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(l10n.students),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              selectedColor: AppTheme.primaryBlue.withAlpha(30),
              checkmarkColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: selected == null
                    ? AppTheme.primaryBlue
                    : AppTheme.textMuted,
                fontWeight:
                    selected == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Stage chips
          ...stages.map((stage) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: FilterChip(
                  label: Text(stage),
                  selected: selected == stage,
                  onSelected: (_) =>
                      onSelected(selected == stage ? null : stage),
                  selectedColor: AppTheme.primaryBlue.withAlpha(30),
                  checkmarkColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: selected == stage
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted,
                    fontWeight:
                        selected == stage ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Card
// ─────────────────────────────────────────────────────────────────────────────

class _StudentCard extends StatefulWidget {
  final AppUser student;
  final DataProvider data;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.data,
    required this.onDelete,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = widget.student;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              student.isDisabled ? Colors.grey : AppTheme.primaryBlue,
          child: Text(
            student.name.isNotEmpty ? student.name[0] : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(student.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            // Student Code badge
            if (student.studentCode.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.deepNavy.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.deepNavy.withAlpha(50)),
                ),
                child: Text(
                  student.studentCode,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.deepNavy,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            if (student.isDisabled) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n.disabled,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.errorRed)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${student.phone}  •  ${student.grade}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info rows ──────────────────────────────────────────────
                _infoRow(Icons.phone, l10n.phoneNumber, student.phone),
                _infoRow(Icons.school, l10n.stage, student.grade),
                _infoRow(
                  Icons.calendar_today,
                  l10n.registrationDate,
                  '${student.createdAt.day}/${student.createdAt.month}/${student.createdAt.year}',
                ),
                const SizedBox(height: 12),

                // ── QR Code ────────────────────────────────────────────────
                _buildQrSection(context, student),
                const SizedBox(height: 12),

                // ── Password ───────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.primaryBlue.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text('${l10n.passwordLabel}: ',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      Expanded(
                        child: Text(
                          student.password.isEmpty
                              ? l10n.notSaved
                              : _showPassword
                                  ? student.password
                                  : '••••••',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: student.password.isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.textDark,
                            fontFamily: _showPassword ? null : 'monospace',
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      if (student.password.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Used codes ─────────────────────────────────────────────
                FutureBuilder<List<AccessCode>>(
                  future: widget.data.getCodesUsedByStudent(student.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                          height: 24,
                          child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final codes = snapshot.data ?? [];
                    if (codes.isEmpty) {
                      return Text(l10n.noUsedCodes,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.usedCodes} (${codes.length}):',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        ...codes.map((c) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('• ${c.code}',
                                  style: const TextStyle(
                                      fontSize: 12, fontFamily: 'monospace')),
                            )),
                      ],
                    );
                  },
                ),
                const Divider(height: 20),

                // ── Actions ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.disableAccount,
                            style: const TextStyle(fontSize: 13)),
                        value: student.isDisabled,
                        onChanged: (value) => widget.data
                            .toggleStudentDisabled(student.uid, value),
                        activeThumbColor: AppTheme.errorRed,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_forever,
                          color: AppTheme.errorRed),
                      tooltip: l10n.deleteAccount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── QR Code section ──────────────────────────────────────────────────────
  Widget _buildQrSection(BuildContext context, AppUser student) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // QR preview
          GestureDetector(
            onTap: () => _showQrDialog(context, student),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: student.uid,
                version: QrVersions.auto,
                size: 72,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qrCode,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  student.studentCode.isNotEmpty
                      ? student.studentCode
                      : student.uid.substring(0, 8).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => _showQrDialog(context, student),
                  icon: const Icon(Icons.fullscreen,
                      size: 16, color: AppTheme.primaryBlue),
                  label: Text(
                    l10n.fullScreen,
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Full QR dialog ───────────────────────────────────────────────────────
  void _showQrDialog(BuildContext context, AppUser student) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      student.name[0],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          student.grade,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code large
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: student.uid,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student code
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.deepNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  student.studentCode.isNotEmpty
                      ? student.studentCode
                      : student.uid.substring(0, 8).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                student.phone,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
