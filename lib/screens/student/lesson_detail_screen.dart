import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/video_player_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  // ❌ حذفنا _recordView - التسجيل يحصل في video_player_widget فقط

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
