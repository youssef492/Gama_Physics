import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/announcement_seen_service.dart';
import '../../services/announcement_view_service.dart';
import 'package:intl/intl.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final Set<String> _recordedAnnouncements = {};

  @override
  void initState() {
    super.initState();
    context.read<DataProvider>().listenToAnnouncements();
    // فور ما الشاشة تفتح → نحفظ الوقت الحالي كـ "آخر مرة شاف"
    AnnouncementSeenService.markAsSeen();
  }

  void _recordViewIfNeeded(String announcementId, BuildContext context) {
    if (_recordedAnnouncements.contains(announcementId)) return;
    _recordedAnnouncements.add(announcementId);

    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.role == 'student') {
      AnnouncementViewService.recordView(
        announcementId: announcementId,
        studentId: user.uid,
        studentName: user.name,
        studentPhone: user.phone,
        studentGrade: user.grade,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final DateFormat formatter = DateFormat('d MMM yyyy  hh:mm a', locale);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.announcements),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
            ),
          ),
        ),
      ),
      body: data.announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(l10n.noAnnouncements,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.announcements.length,
              itemBuilder: (context, index) {
                final ann = data.announcements[index];
                _recordViewIfNeeded(ann.id, context);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          AppTheme.primaryBlue.withAlpha(10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.campaign,
                                color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ann.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(),
                        ),
                        Text(
                          ann.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ann.authorName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formatter.format(ann.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
