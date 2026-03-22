import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../models/app_user.dart';
import '../../models/access_code.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DataProvider>().listenToStudents();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final filteredStudents = data.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.contains(_searchQuery) || s.phone.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageStudents)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchStudents,
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${l10n.studentCount}: ${filteredStudents.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Text(l10n.noStudents,
                        style: const TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
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
            if (student.isDisabled)
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
        ),
        subtitle: Text(student.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.school, l10n.stage, student.grade),
                _infoRow(Icons.phone, l10n.phoneNumber, student.phone),
                _infoRow(
                  Icons.calendar_today,
                  l10n.registrationDate,
                  '${student.createdAt.day}/${student.createdAt.month}/${student.createdAt.year}',
                ),
                const SizedBox(height: 8),
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
