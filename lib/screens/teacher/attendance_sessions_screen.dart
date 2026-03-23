import 'package:flutter/material.dart';
import 'package:GAMA/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_session.dart';
import '../../services/firestore_service.dart';
import '../../config/theme.dart';

class AttendanceSessionsScreen extends StatefulWidget {
  const AttendanceSessionsScreen({super.key});

  @override
  State<AttendanceSessionsScreen> createState() =>
      _AttendanceSessionsScreenState();
}

class _AttendanceSessionsScreenState extends State<AttendanceSessionsScreen> {
  final FirestoreService _firestore = FirestoreService();

  Future<void> _createNewSession(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.newSession),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.sessionTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.sessionDate),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final newSession = await _firestore.createAttendanceSession(
                    selectedDate,
                    titleController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      '/take-attendance',
                      arguments: newSession,
                    );
                  }
                },
                child: Text(l10n.add),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attendance),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewSession(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSession),
        backgroundColor: AppTheme.accentCyan,
      ),
      body: StreamBuilder<List<AttendanceSession>>(
        stream: _firestore.getAttendanceSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading sessions'));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions yet.'));
          }

          return ListView.builder(
            padding:
                const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateStr = DateFormat('yyyy-MM-dd').format(session.date);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    session.title.isEmpty ? l10n.attendance : session.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      '$dateStr - ${session.presentStudents.length} ${l10n.students}'),
                  trailing: session.isEnded
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/take-attendance',
                      arguments: session,
                    );
                  },
                  onLongPress: () async {
                    // Delete confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _firestore.deleteAttendanceSession(session.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
