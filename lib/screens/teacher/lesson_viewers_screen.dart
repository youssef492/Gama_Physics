import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/lesson.dart';
import '../../models/video_view.dart';
import '../../services/video_view_service.dart';

class LessonViewersScreen extends StatelessWidget {
  const LessonViewersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lesson = ModalRoute.of(context)?.settings.arguments as Lesson?;
    final l10n = AppLocalizations.of(context)!;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text(l10n.lessonNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.lessonViewers,
          style: const TextStyle(fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              lesson.title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<VideoView>>(
        stream: VideoViewService.getViewsForLesson(lesson.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    l10n.failedToLoadData,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // إعادة بناء الـ widget
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // ✅ تحسين: نعرض loading فقط لو waiting والبيانات مش موجودة
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loading,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // ✅ تحسين: نستخدم البيانات حتى لو الـ connectionState لسه waiting
          // (يعني البيانات من cache بس الـ stream لسه بيحمّل من الـ server)
          final views = snap.data ?? [];

          // ─── Empty ─────────────────────────────────────────────────────────
          if (views.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 72, color: AppTheme.textMuted.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLessonViewers,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // ─── Stats header ──────────────────────────────────────────────────
          final totalWatches =
              views.fold<int>(0, (sum, v) => sum + v.watchCount);

          return Column(
            children: [
              // Stats bar
              Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryBlue.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_outline,
                      label: l10n.studentWatched,
                      value: '${views.length}',
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 16),
                    Container(
                        width: 1,
                        height: 36,
                        color: AppTheme.primaryBlue.withAlpha(30)),
                    const SizedBox(width: 16),
                    _StatChip(
                      icon: Icons.remove_red_eye_outlined,
                      label: l10n.totalViews,
                      value: '$totalWatches',
                      color: AppTheme.accentCyan,
                    ),
                  ],
                ),
              ),

              // ─── List ──────────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: views.length,
                  itemBuilder: (_, i) => _ViewerCard(view: views[i], index: i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Viewer Card ──────────────────────────────────────────────────────────────
class _ViewerCard extends StatelessWidget {
  final VideoView view;
  final int index;

  const _ViewerCard({required this.view, required this.index});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('d MMM yyyy  hh:mm a', locale);
    final fmtShort = DateFormat('d/M/yyyy', locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar ──────────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  view.studentName.isNotEmpty ? view.studentName[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ─── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + watch count badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          view.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // عدد المرات
                      if (view.watchCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.accentCyan.withAlpha(80)),
                          ),
                          child: Text(
                            l10n.timesWatched(view.watchCount),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Phone
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        view.studentPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Grade
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        view.studentGrade,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Dates
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _DateRow(
                          icon: Icons.play_arrow_rounded,
                          label: l10n.firstWatch,
                          value: fmtShort.format(view.firstWatchedAt),
                          color: AppTheme.freeGreen,
                        ),
                        if (view.watchCount > 1) ...[
                          const SizedBox(height: 4),
                          _DateRow(
                            icon: Icons.update_rounded,
                            label: l10n.lastWatch,
                            value: fmt.format(view.lastWatchedAt),
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Row ─────────────────────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
