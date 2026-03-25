import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/access_code.dart';
import '../../services/firestore_service.dart';
import '../../services/excel_export_service.dart';

class ManageCodesScreen extends StatefulWidget {
  const ManageCodesScreen({super.key});

  @override
  State<ManageCodesScreen> createState() => _ManageCodesScreenState();
}

class _ManageCodesScreenState extends State<ManageCodesScreen> {
  Map<String, String> _lessonTitles = {};
  bool _isExporting = false;
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _loadedLessonIds = {};

  @override
  void initState() {
    super.initState();
    final data = context.read<DataProvider>();
    data.listenToAllCodes();
    data.listenToAllPaidLessons();
  }

  Future<void> _loadNewLessonTitles(List<AccessCode> codes) async {
    final newIds =
        codes.map((c) => c.lessonId).toSet().difference(_loadedLessonIds);
    if (newIds.isEmpty) return;
    _loadedLessonIds.addAll(newIds);
    final titles = await _firestoreService.getLessonTitles(newIds.toList());
    if (mounted) {
      setState(() => _lessonTitles = {..._lessonTitles, ...titles});
    }
  }

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _exportToExcel(
      BuildContext context, List<AccessCode> codes) async {
    if (codes.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final isArabic = context.read<LanguageProvider>().isArabic;
      final filePath = await ExcelExportService.exportCodes(
        codes: codes,
        lessonTitles: _lessonTitles,
        isArabic: isArabic,
      );
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => ExportSuccessDialog(
            filePath: filePath,
            isArabic: isArabic,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    if (data.codes.isNotEmpty) {
      _loadNewLessonTitles(data.codes);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCodes),
        actions: [
          if (data.codes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              tooltip: l10n.editExpiryTooltip,
              onPressed: () => _showBulkExpiryDialog(context, data),
            ),
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
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: l10n.exportExcel,
                    onPressed: () => _exportToExcel(context, data.codes),
                  ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: isArabic ? 'حذف أكواد درس' : 'Delete lesson codes',
              onPressed: () => _showDeleteByLessonDialog(context, data),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGenerateDialog(context, data),
        child: const Icon(Icons.add),
      ),
      body: data.codes.isEmpty
          ? Center(
              child: Text(l10n.noCodes,
                  style: const TextStyle(color: AppTheme.textMuted)))
          : Column(
              children: [
                _ExportBanner(
                  codesCount: data.codes.length,
                  isExporting: _isExporting,
                  onExport: () => _exportToExcel(context, data.codes),
                ),
                _buildLessonSummaries(context, data.codes),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.codes.length,
                    itemBuilder: (context, index) {
                      final code = data.codes[index];
                      return _buildCodeCard(context, data, code, l10n);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Lesson summaries strip ────────────────────────────────────────────────
  Widget _buildLessonSummaries(BuildContext context, List<AccessCode> codes) {
    if (codes.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final Map<String, List<AccessCode>> grouped = {};
    for (var code in codes) {
      grouped.putIfAbsent(code.lessonId, () => []).add(code);
    }
    final lessons = grouped.entries.toList();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lessonId = lessons[index].key;
          final lessonCodes = lessons[index].value;
          final title = _lessonTitles[lessonId] ?? '...';

          return Container(
            width: 180,
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${lessonCodes.length} ${l10n.codes}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () => _exportToExcel(context, lessonCodes),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Code card ─────────────────────────────────────────────────────────────
  Widget _buildCodeCard(BuildContext context, DataProvider data,
      AccessCode code, AppLocalizations l10n) {
    final isArabic = context.read<LanguageProvider>().isArabic;

    Color statusColor;
    String statusText;
    switch (code.status) {
      case 'active':
        statusColor = AppTheme.successGreen;
        statusText = l10n.active;
        break;
      case 'used':
        statusColor = AppTheme.warningOrange;
        statusText = l10n.used;
        break;
      case 'expired':
        statusColor = AppTheme.errorRed;
        statusText = l10n.expired;
        break;
      case 'disabled':
        statusColor = Colors.grey;
        statusText = l10n.disabled;
        break;
      default:
        statusColor = Colors.grey;
        statusText = code.status;
    }

    final lessonTitle = _lessonTitles[code.lessonId] ?? '...';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.vpn_key, color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              code.code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusText,
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_lesson,
                    size: 12, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lessonTitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('${l10n.usage}: ${code.currentUses}/${code.maxUses}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (code.expiresAt != null)
                  Text(
                    '${l10n.expiresOn}: ${code.expiresAt!.day}/${code.expiresAt!.month}/${code.expiresAt!.year}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                if (code.usedBy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l10n.usedBy,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  ...code.usedBy.map((u) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${u.studentName} - ${u.usedAt.day}/${u.usedAt.month}/${u.usedAt.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                ],
                const SizedBox(height: 8),
                // ─── Action buttons ───────────────────────────────────────
                Wrap(
                  spacing: 0,
                  children: [
                    // Copy
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code.code));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(l10n.copied)));
                      },
                      tooltip: l10n.copy,
                    ),
                    // Edit expiry
                    IconButton(
                      icon: const Icon(Icons.edit_calendar,
                          color: AppTheme.primaryBlue, size: 20),
                      onPressed: () =>
                          _showSingleExpiryDialog(context, data, code),
                      tooltip: l10n.editExpiryTooltip,
                    ),
                    // Edit max uses
                    IconButton(
                      icon: const Icon(Icons.repeat,
                          color: AppTheme.warningOrange, size: 20),
                      onPressed: () =>
                          _showEditMaxUsesDialog(context, data, code),
                      tooltip:
                          isArabic ? 'تعديل عدد الاستخدامات' : 'Edit max uses',
                    ),
                    // Disable / Enable
                    if (code.status == 'active')
                      IconButton(
                        icon: const Icon(Icons.block,
                            color: AppTheme.errorRed, size: 20),
                        onPressed: () => data.disableCode(code.id),
                        tooltip: l10n.disable,
                      ),
                    if (code.status == 'disabled')
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: AppTheme.successGreen, size: 20),
                        onPressed: () => data.enableCode(code.id),
                        tooltip: l10n.enable,
                      ),
                    // Delete single code
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorRed, size: 20),
                      onPressed: () =>
                          _showDeleteCodeDialog(context, data, code),
                      tooltip: isArabic ? 'حذف الكود' : 'Delete code',
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

  // ─── Edit max uses dialog ──────────────────────────────────────────────────
  void _showEditMaxUsesDialog(
      BuildContext context, DataProvider data, AccessCode code) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: code.maxUses.toString());
    bool isLoading = false;
    final lessonTitle = _lessonTitles[code.lessonId] ?? '...';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.repeat, color: AppTheme.warningOrange, size: 22),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'تعديل عدد الاستخدامات' : 'Edit Max Uses',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Code info ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lessonTitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Current usage chip ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.warningOrange.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warningOrange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'الاستخدام الحالي: ${code.currentUses} من ${code.maxUses}'
                          : 'Current usage: ${code.currentUses} of ${code.maxUses}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.warningOrange),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الحد الأقصى للاستخدامات' : 'Max uses',
                  prefixIcon: const Icon(Icons.repeat),
                  helperText: isArabic
                      ? 'يجب أن يكون ≥ ${code.currentUses}'
                      : 'Must be ≥ ${code.currentUses}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(l10n.save),
              onPressed: isLoading
                  ? null
                  : () async {
                      final newMax = int.tryParse(controller.text.trim()) ?? 0;

                      if (newMax <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic
                                ? 'يجب أن يكون العدد أكبر من صفر'
                                : 'Value must be greater than zero'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      if (newMax < code.currentUses) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic
                                ? 'لا يمكن أن يكون الحد أقل من الاستخدام الحالي (${code.currentUses})'
                                : 'Cannot be less than current usage (${code.currentUses})'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      setS(() => isLoading = true);
                      await data.updateCodeMaxUses(code.id, newMax);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic
                                ? 'تم تحديث الحد الأقصى إلى $newMax استخدامات'
                                : 'Max uses updated to $newMax'),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete single code dialog ─────────────────────────────────────────────
  void _showDeleteCodeDialog(
      BuildContext context, DataProvider data, AccessCode code) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final l10n = AppLocalizations.of(context)!;
    bool isLoading = false;
    final lessonTitle = _lessonTitles[code.lessonId] ?? '...';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever,
                  color: AppTheme.errorRed, size: 22),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'حذف الكود' : 'Delete Code',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Code preview ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorRed.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 3,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lessonTitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Warning ──
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
                        isArabic
                            ? 'سيتم حذف هذا الكود نهائياً ولا يمكن التراجع عن هذا الإجراء.'
                            : 'This code will be permanently deleted and cannot be undone.',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.errorRed),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Extra warning if code is already used ──
              if (code.usedBy.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.warningOrange.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: AppTheme.warningOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'تنبيه: هذا الكود تم استخدامه بالفعل من ${code.usedBy.length} طالب.'
                              : 'Warning: This code has been used by ${code.usedBy.length} student(s).',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.warningOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_forever, size: 18),
              label: Text(l10n.deleteBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setS(() => isLoading = true);
                      await data.deleteCode(code.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic
                                ? 'تم حذف الكود ${code.code} بنجاح'
                                : 'Code ${code.code} deleted successfully'),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bulk expiry dialog ────────────────────────────────────────────────────
  void _showBulkExpiryDialog(BuildContext context, DataProvider data) {
    final l10n = AppLocalizations.of(context)!;
    final paidLessons = data.allPaidLessons;
    String? selectedLessonId;
    DateTime? pickedDate;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar,
                  color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Text(l10n.editExpiryTitle, style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.bulkExpirySubtitle,
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                if (paidLessons.isEmpty)
                  Text(l10n.noPaidLessons,
                      style: const TextStyle(color: AppTheme.errorRed))
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedLessonId,
                    decoration: InputDecoration(
                      labelText: l10n.lessonDropdownLabel,
                      prefixIcon: const Icon(Icons.play_lesson),
                    ),
                    isExpanded: true,
                    items: paidLessons
                        .map((l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.title,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => selectedLessonId = v),
                  ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: pickedDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) setS(() => pickedDate = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: pickedDate != null
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade300,
                        width: pickedDate != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: pickedDate != null
                              ? AppTheme.primaryBlue
                              : AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedDate != null
                                ? '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}'
                                : l10n.pickExpiryDate,
                            style: TextStyle(
                              color: pickedDate != null
                                  ? AppTheme.textDark
                                  : AppTheme.textMuted,
                              fontWeight: pickedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (pickedDate != null)
                          GestureDetector(
                            onTap: () => setS(() => pickedDate = null),
                            child: const Icon(Icons.close,
                                size: 16, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
                if (pickedDate != null &&
                    DateTime.now().isAfter(pickedDate!)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppTheme.warningOrange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.pastDateWarningBulk,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.warningOrange),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(l10n.update),
              onPressed:
                  (selectedLessonId == null || pickedDate == null || isLoading)
                      ? null
                      : () async {
                          setS(() => isLoading = true);
                          final count = await data.bulkUpdateExpiryByLesson(
                              selectedLessonId!, pickedDate);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.bulkUpdateSuccess(count,
                                    '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}')),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Single code expiry dialog ─────────────────────────────────────────────
  void _showSingleExpiryDialog(
      BuildContext context, DataProvider data, AccessCode code) {
    final l10n = AppLocalizations.of(context)!;
    DateTime? pickedDate = code.expiresAt;
    bool isLoading = false;
    final lessonTitle = _lessonTitles[code.lessonId] ?? '...';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar,
                  color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Text(l10n.editExpirySingleTitle,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(lessonTitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) setS(() => pickedDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: pickedDate != null
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade300,
                      width: pickedDate != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: pickedDate != null
                            ? AppTheme.primaryBlue
                            : AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pickedDate != null
                              ? '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}'
                              : l10n.pickNewDate,
                          style: TextStyle(
                            color: pickedDate != null
                                ? AppTheme.textDark
                                : AppTheme.textMuted,
                            fontWeight: pickedDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (pickedDate != null)
                        GestureDetector(
                          onTap: () => setS(() => pickedDate = null),
                          child: const Icon(Icons.close,
                              size: 16, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              if (pickedDate != null &&
                  DateTime.now().isAfter(pickedDate!)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppTheme.warningOrange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.pastDateWarningSingle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.warningOrange),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(l10n.save),
              onPressed: isLoading
                  ? null
                  : () async {
                      setS(() => isLoading = true);
                      await data.updateCodeExpiry(code.id, pickedDate);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(pickedDate != null
                                ? l10n.singleUpdateSuccess(
                                    '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}')
                                : l10n.expiryRemoved),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete by lesson dialog ───────────────────────────────────────────────
  void _showDeleteByLessonDialog(BuildContext context, DataProvider data) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final l10n = AppLocalizations.of(context)!;
    final paidLessons = data.allPaidLessons;
    String? selectedLessonId;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_sweep,
                  color: AppTheme.errorRed, size: 22),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'حذف أكواد درس' : 'Delete lesson codes',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paidLessons.isEmpty)
                Text(l10n.noPaidLessons,
                    style: const TextStyle(color: AppTheme.errorRed))
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedLessonId,
                  decoration:
                      InputDecoration(labelText: l10n.lessonDropdownLabel),
                  isExpanded: true,
                  items: paidLessons
                      .map((l) => DropdownMenuItem(
                            value: l.id,
                            child:
                                Text(l.title, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selectedLessonId = v),
                ),
              const SizedBox(height: 12),
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
                        isArabic
                            ? 'سيتم حذف كل الأكواد المرتبطة بهذا الدرس نهائياً.'
                            : 'All codes for this lesson will be permanently deleted.',
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
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_forever, size: 18),
              label: Text(l10n.deleteBtn),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white),
              onPressed: (selectedLessonId == null || isLoading)
                  ? null
                  : () async {
                      setS(() => isLoading = true);
                      final count =
                          await data.deleteCodesByLesson(selectedLessonId!);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isArabic
                              ? 'تم حذف $count كود بنجاح'
                              : 'Deleted $count codes successfully'),
                          backgroundColor: AppTheme.successGreen,
                        ));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Generate codes dialog ─────────────────────────────────────────────────
  void _showGenerateDialog(BuildContext context, DataProvider data) {
    final l10n = AppLocalizations.of(context)!;
    final countController = TextEditingController(text: '1');
    final maxUsesController = TextEditingController(text: '3');
    final daysController = TextEditingController(text: '30');
    String? selectedLessonId;
    final paidLessons = data.allPaidLessons;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.generateCodes),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (paidLessons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      l10n.noLessons,
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedLessonId,
                    decoration: InputDecoration(labelText: l10n.lessons),
                    isExpanded: true,
                    items: paidLessons.map((l) {
                      return DropdownMenuItem(
                        value: l.id,
                        child: Text(l.title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedLessonId = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.codesCount),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxUsesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.maxUses),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.validity),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: selectedLessonId == null
                  ? null
                  : () async {
                      final count = int.tryParse(countController.text) ?? 1;
                      final maxUses = int.tryParse(maxUsesController.text) ?? 3;
                      final days = int.tryParse(daysController.text) ?? 30;
                      final auth = context.read<AuthProvider>();

                      for (int i = 0; i < count; i++) {
                        await data.addCode(AccessCode(
                          id: '',
                          code: _generateCode(6),
                          lessonId: selectedLessonId!,
                          maxUses: maxUses,
                          expiresAt: DateTime.now().add(Duration(days: days)),
                          createdBy: auth.currentUser?.uid ?? '',
                        ));
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.generatedSuccess(count))),
                        );
                      }
                    },
              child: Text(l10n.generate),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Export Banner ────────────────────────────────────────────────────────────
class _ExportBanner extends StatelessWidget {
  final int codesCount;
  final bool isExporting;
  final VoidCallback onExport;

  const _ExportBanner({
    required this.codesCount,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withAlpha(15),
        border: Border.all(color: AppTheme.successGreen.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, color: AppTheme.successGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$codesCount ${l10n.codes}',
              style: const TextStyle(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.successGreen),
                )
              : TextButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.download,
                      size: 16, color: AppTheme.successGreen),
                  label: const Text(
                    'Export Excel',
                    style: TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
        ],
      ),
    );
  }
}
