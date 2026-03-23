import 'package:flutter/material.dart';
import 'package:GAMA/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../models/lesson.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

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
                return LessonCard(
                  lesson: lesson,
                  showVisibility: true,
                  onTap: () =>
                      _showAddEditDialog(context, data, lesson: lesson),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: lesson.isVisible,
                        onChanged: (value) =>
                            data.toggleLessonVisibility(lesson.id, value),
                        activeThumbColor: AppTheme.successGreen,
                      ),
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
