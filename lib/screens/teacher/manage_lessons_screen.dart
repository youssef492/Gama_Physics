import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../models/lesson.dart';
import '../../services/video_view_service.dart';
import '../../widgets/lesson_card.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  String? stageId;
  String? semesterId;
  String? semesterName;

  // cache عدد المشاهدين لكل درس عشان ما نعملش request كل rebuild
  final Map<String, int> _viewerCounts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && semesterId == null) {
      stageId = args['stageId'] as String;
      semesterId = args['semesterId'] as String;
      semesterName = args['semesterName'] as String;
      context.read<DataProvider>().listenToLessons(semesterId!);
    }
  }

  // نجيب عدد المشاهدين لكل درس بعد ما الـ lessons تتحمل
  Future<void> _loadViewerCounts(List<Lesson> lessons) async {
    for (final lesson in lessons) {
      if (!_viewerCounts.containsKey(lesson.id)) {
        final count = await VideoViewService.getUniqueViewersCount(lesson.id);
        if (mounted) {
          setState(() => _viewerCounts[lesson.id] = count);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    // نحمّل عدد المشاهدين لأي درس جديد
    if (data.lessons.isNotEmpty) {
      _loadViewerCounts(data.lessons);
    }

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.lessons}: ${semesterName ?? ''}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, data),
        child: const Icon(Icons.add),
      ),
      body: data.lessons.isEmpty
          ? Center(
              child: Text(l10n.noLessons,
                  style: const TextStyle(color: AppTheme.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.lessons.length,
              itemBuilder: (context, index) {
                final lesson = data.lessons[index];
                final viewerCount = _viewerCounts[lesson.id];

                return LessonCard(
                  lesson: lesson,
                  showVisibility: true,
                  onTap: () =>
                      _showAddEditDialog(context, data, lesson: lesson),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── زرار المشاهدين ────────────────────────────────
                      _ViewersButton(
                        count: viewerCount,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/lesson-viewers',
                          arguments: lesson,
                        ),
                      ),
                      // ─── Toggle visibility ─────────────────────────────
                      Switch(
                        value: lesson.isVisible,
                        onChanged: (value) =>
                            data.toggleLessonVisibility(lesson.id, value),
                        activeThumbColor: AppTheme.successGreen,
                      ),
                      // ─── Delete ────────────────────────────────────────
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: AppTheme.errorRed),
                        onPressed: () => _confirmDelete(
                            context, data, lesson.id, lesson.title),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddEditDialog(BuildContext context, DataProvider data,
      {Lesson? lesson}) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final descController =
        TextEditingController(text: lesson?.description ?? '');
    final urlController = TextEditingController(text: lesson?.videoUrl ?? '');
    final orderController = TextEditingController(
        text: (lesson?.order ?? data.lessons.length + 1).toString());
    String videoType = lesson?.videoType ?? 'youtube';
    String lessonType = lesson?.lessonType ?? 'free';
    bool isVisible = lesson?.isVisible ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lesson == null ? l10n.addLesson : l10n.editLesson),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.lessonTitle),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(labelText: l10n.lessonDescription),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.videoUrl,
                    hintText: 'YouTube or Google Drive URL',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: videoType,
                  decoration: InputDecoration(labelText: l10n.videoType),
                  items: const [
                    DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                    DropdownMenuItem(
                        value: 'drive', child: Text('Google Drive')),
                  ],
                  onChanged: (v) => setDialogState(() => videoType = v!),
                ),
                if (videoType == 'youtube') ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.youtubeHint,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.35),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: lessonType,
                  decoration: InputDecoration(labelText: l10n.lessonType),
                  items: [
                    DropdownMenuItem(value: 'free', child: Text(l10n.free)),
                    DropdownMenuItem(value: 'paid', child: Text(l10n.paid)),
                  ],
                  onChanged: (v) => setDialogState(() => lessonType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.order),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(l10n.visibleToStudents),
                  value: isVisible,
                  onChanged: (v) => setDialogState(() => isVisible = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isEmpty || url.isEmpty) return;
                final orderNum = int.tryParse(orderController.text) ?? 1;

                if (lesson == null) {
                  await data.addLesson(Lesson(
                    id: '',
                    stageId: stageId!,
                    semesterId: semesterId!,
                    title: title,
                    description: descController.text.trim(),
                    videoUrl: url,
                    videoType: videoType,
                    lessonType: lessonType,
                    isVisible: isVisible,
                    order: orderNum,
                  ));
                } else {
                  await data.updateLesson(lesson.id, {
                    'title': title,
                    'description': descController.text.trim(),
                    'videoUrl': url,
                    'videoType': videoType,
                    'lessonType': lessonType,
                    'isVisible': isVisible,
                    'order': orderNum,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(lesson == null ? l10n.add : l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, DataProvider data, String id, String title) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text('${l10n.deleteStageConfirm} "$title"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await data.deleteLesson(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Viewers Button Widget ────────────────────────────────────────────────────
class _ViewersButton extends StatelessWidget {
  final int? count;
  final VoidCallback onTap;

  const _ViewersButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primaryBlue.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_outlined,
                size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            count == null
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppTheme.primaryBlue),
                  )
                : Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
