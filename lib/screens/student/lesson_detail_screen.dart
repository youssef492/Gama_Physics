import 'package:flutter/material.dart';
import 'package:GAMA/l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../widgets/video_player_widget.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = ModalRoute.of(context)?.settings.arguments as Lesson?;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    return _LessonDetailView(lesson: lesson, l10n: l10n);
  }
}

class _LessonDetailView extends StatefulWidget {
  final Lesson lesson;
  final AppLocalizations l10n;

  const _LessonDetailView({
    required this.lesson,
    required this.l10n,
  });

  @override
  State<_LessonDetailView> createState() => _LessonDetailViewState();
}

class _LessonDetailViewState extends State<_LessonDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar دايماً موجود - مش بنشيله
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VideoPlayerWidget بيتعمل مرة واحدة بس ومش بيتعمل recreate
            VideoPlayerWidget(
              embedUrl: widget.lesson.videoUrl,
              videoType: widget.lesson.videoType,
              title: widget.lesson.title,
              rawVideoUrl: widget.lesson.videoUrl,
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
                          widget.lesson.title,
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
                          color: widget.lesson.isFree
                              ? AppTheme.freeGreen.withAlpha(25)
                              : AppTheme.paidOrange.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.lesson.isFree
                              ? widget.l10n.free
                              : widget.l10n.paid,
                          style: TextStyle(
                            color: widget.lesson.isFree
                                ? AppTheme.freeGreen
                                : AppTheme.paidOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.lesson.description.isNotEmpty) ...[
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
                                widget.l10n.lessonDescription,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lesson.description,
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
