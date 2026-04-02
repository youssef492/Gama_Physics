import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/widgets/drive_image_viewer_widget.dart';
import 'package:gama/widgets/pdf_viewer_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'
    show canLaunchUrl, LaunchMode, launchUrl;
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
                        if (ann.pdfUrl != null && ann.pdfUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _PdfAttachmentButton(
                            pdfUrl: ann.pdfUrl!,
                            title: ann.title,
                          ),
                        ],
                        if (ann.imageUrl != null && ann.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _ImageAttachmentCard(
                            imageUrl: ann.imageUrl!,
                            title: ann.title,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PdfAttachmentButton extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const _PdfAttachmentButton({
    required this.pdfUrl,
    required this.title,
  });

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  String? _extractFileId(String url) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) return null;

    if (normalizedUrl.contains('/file/d/')) {
      final parts = normalizedUrl.split('/file/d/');
      if (parts.length > 1) return parts[1].split('/').first.split('?').first;
    }

    if (normalizedUrl.contains('/d/')) {
      final parts = normalizedUrl.split('/d/');
      if (parts.length > 1) return parts[1].split('/').first.split('?').first;
    }

    return Uri.tryParse(normalizedUrl)?.queryParameters['id'];
  }

  Future<void> _openOnWindows() async {
    final fileId = _extractFileId(pdfUrl);
    final previewUrl = fileId == null
        ? pdfUrl
        : 'https://drive.google.com/file/d/$fileId/preview?rm=minimal';
    final uri = Uri.tryParse(previewUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryBlue,
          side: const BorderSide(color: AppTheme.primaryBlue),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: Text(
          l10n.viewPdf, // أضيف المفتاح ده في ملف الترجمة
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          if (_isWindows) {
            // Windows → فتح في المتصفح مباشرة
            _openOnWindows();
          } else {
            // Android / iOS → PdfViewerWidget الموجود عندك
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerWidget(
                  pdfUrl: pdfUrl,
                  title: title,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ImageAttachmentCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _ImageAttachmentCard({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DriveImage(
            sourceUrl: imageUrl,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            invalidLabel: l10n.invalidImageUrl,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriveImageViewerWidget(
                    imageUrl: imageUrl,
                    title: title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(
              l10n.viewImage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
