import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/pdf_viewer_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {

  String? _extractFileIdFromUrl(String url) {
    try {
      debugPrint('════════════════════════════════════');
      debugPrint('[LESSON DETAIL] Checking PDF URL validity');
      debugPrint('[LESSON DETAIL] URL: $url');

      String normalizedUrl = url;

      if (normalizedUrl.contains('/file/d/')) {
        final parts = normalizedUrl.split('/file/d/');
        if (parts.length > 1) {
          final fileIdPart = parts[1];
          final fileId = fileIdPart.split('/').first;
          if (fileId.isNotEmpty && fileId.length > 10) {
            debugPrint(
                '[LESSON DETAIL] ✅ Valid: Found file ID from /file/d/: $fileId');
            return fileId;
          }
        }
      }

      // Try extracting from /d/ pattern (used in share links)
      if (normalizedUrl.contains('/d/')) {
        final parts = normalizedUrl.split('/d/');
        if (parts.length > 1) {
          final fileIdPart = parts[1];
          final fileId = fileIdPart.split('/').first.split('?').first;
          if (fileId.isNotEmpty && fileId.length > 10) {
            debugPrint(
                '[LESSON DETAIL] ✅ Valid: Found file ID from /d/: $fileId');
            return fileId;
          }
        }
      }

      // Try URI parsing as fallback
      final uri = Uri.tryParse(normalizedUrl);
      if (uri != null) {
        final idFromQuery = uri.queryParameters['id'];
        if (idFromQuery != null && idFromQuery.isNotEmpty) {
          debugPrint(
              '[LESSON DETAIL] ✅ Valid: Found file ID from query: $idFromQuery');
          return idFromQuery;
        }

        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          for (int i = 0; i < segments.length - 1; i++) {
            if ((segments[i] == 'file' || segments[i] == 'd') &&
                segments[i + 1].isNotEmpty &&
                segments[i + 1].length > 10) {
              debugPrint(
                  '[LESSON DETAIL] ✅ Valid: Found file ID from segments: ${segments[i + 1]}');
              return segments[i + 1];
            }
          }
        }
      }

      debugPrint('[LESSON DETAIL] ❌ Invalid: Could not extract file ID');
      return null;
    } catch (e) {
      debugPrint('[LESSON DETAIL] ❌ Exception: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = ModalRoute.of(context)?.settings.arguments as Lesson?;
    debugPrint('videoUrl: ${lesson?.videoUrl}');
    debugPrint('videoType: ${lesson?.videoType}');
    debugPrint('══════════════════════════════');
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.lessonNotFound)),
      );
    }

    // ✅ نجيب بيانات الطالب مرة واحدة هنا
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final isStudent = auth.isStudent;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.hasVideo)
              // ✅ نمرر بيانات الطالب للـ video player
              VideoPlayerWidget(
                embedUrl: lesson.videoUrl,
                videoType: lesson.videoType,
                title: lesson.title,
                rawVideoUrl: lesson.videoUrl,
                // ✅ التسجيل يحصل هنا في video_player فقط
                lessonId: isStudent ? lesson.id : '',
                studentId: isStudent && user != null ? user.uid : '',
                studentName: isStudent && user != null ? user.name : '',
                studentPhone: isStudent && user != null ? user.phone : '',
                studentGrade: isStudent && user != null ? user.grade : '',
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: lesson.isFree
                              ? AppTheme.freeGreen.withAlpha(25)
                              : AppTheme.paidOrange.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lesson.isFree ? l10n.free : l10n.paid,
                          style: TextStyle(
                            color: lesson.isFree
                                ? AppTheme.freeGreen
                                : AppTheme.paidOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lesson.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryBlue.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description,
                                  size: 18, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                l10n.lessonDescription,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lesson.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppTheme.textDark, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // 📄 PDF Section
                  if (lesson.pdfUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Color(0xFFD32F2F)),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pdfLinks,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lesson.pdfUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final pdfUrl = lesson.pdfUrls[idx];
                        // Check if URL can be parsed to extract file ID
                        final isValid = _extractFileIdFromUrl(pdfUrl) != null;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isValid
                                ? const Color(0xFFD32F2F).withAlpha(10)
                                : Colors.red.withAlpha(10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isValid
                                  ? const Color(0xFFD32F2F).withAlpha(50)
                                  : Colors.red.withAlpha(50),
                            ),
                          ),
                          child: isValid
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${l10n.pdfPreview} ${idx + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pdfUrl
                                                .split('/d/')
                                                .last
                                                .split('/')
                                                .first,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PdfViewerWidget(
                                              pdfUrl: pdfUrl,
                                              title:
                                                  '${lesson.title} - PDF ${idx + 1}',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.open_in_new,
                                          size: 16),
                                      label: Text(l10n.viewPdf),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD32F2F),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    l10n.invalidPdfUrl,
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
