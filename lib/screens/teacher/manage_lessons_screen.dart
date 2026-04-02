import 'dart:async';

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

  StreamSubscription<Map<String, int>>? _countsSub;
  Map<String, int> _viewerCounts = {};

  @override
  void dispose() {
    _countsSub?.cancel();
    super.dispose();
  }

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

  void _subscribeToViewCounts(List<Lesson> lessons) {
    _countsSub?.cancel();
    if (lessons.isEmpty) return;

    final ids = lessons.map((l) => l.id).toList();
    _countsSub = VideoViewService.getViewCountsStream(ids).listen((counts) {
      if (mounted) setState(() => _viewerCounts = counts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    if (data.lessons.isNotEmpty && _countsSub == null) {
      _subscribeToViewCounts(data.lessons);
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
    List<String> pdfUrls = List.from(lesson?.pdfUrls ?? []);
    List<String> imageUrls = List.from(lesson?.imageUrls ?? []);

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
                    hintText: 'Optional (you can create a PDF-only lesson)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: videoType,
                  decoration: InputDecoration(labelText: l10n.videoType),
                  items: [
                    DropdownMenuItem(
                        value: 'youtube', child: Text(l10n.youtube)),
                    DropdownMenuItem(
                        value: 'drive', child: Text(l10n.googleDrive)),
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
                const SizedBox(height: 16),
                // PDF Links Section
                Text(
                  l10n.addPdfLinks,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (pdfUrls.isNotEmpty) ...[
                  Column(
                    children: [
                      for (int idx = 0; idx < pdfUrls.length; idx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    pdfUrls[idx]
                                        .replaceFirst('/d/', '')
                                        .split('/')[0],
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () =>
                                    setDialogState(() => pdfUrls.removeAt(idx)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final pdfController = TextEditingController();
                      showDialog(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: Text(l10n.addPdf),
                          content: TextField(
                            controller: pdfController,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: l10n.pdfUrl,
                              hintText:
                                  'https://drive.google.com/file/d/{FILE_ID}/view',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(_),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final url = pdfController.text.trim();
                                if (url.isNotEmpty &&
                                    (url.contains('drive.google.com') ||
                                        url.contains('/d/'))) {
                                  setDialogState(() => pdfUrls.add(url));
                                  Navigator.pop(_);
                                }
                              },
                              child: Text(l10n.add),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addPdf),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.addImageLinks,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (imageUrls.isNotEmpty) ...[
                  Column(
                    children: [
                      for (int idx = 0; idx < imageUrls.length; idx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${l10n.imagePreview} ${idx + 1}',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => setDialogState(
                                    () => imageUrls.removeAt(idx)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final imageController = TextEditingController();
                      showDialog(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: Text(l10n.addImage),
                          content: TextField(
                            controller: imageController,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: l10n.imageUrl,
                              hintText:
                                  'https://drive.google.com/file/d/{FILE_ID}/view',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(_),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final url = imageController.text.trim();
                                if (url.isNotEmpty &&
                                    (url.contains('drive.google.com') ||
                                        url.contains('/d/'))) {
                                  setDialogState(() => imageUrls.add(url));
                                  Navigator.pop(_);
                                }
                              },
                              child: Text(l10n.add),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.addImage),
                  ),
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
                final hasPdf = pdfUrls.isNotEmpty;
                final hasImages = imageUrls.isNotEmpty;
                if (title.isEmpty) return;
                if (url.isEmpty && !hasPdf && !hasImages) return;
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
                    pdfUrls: pdfUrls,
                    imageUrls: imageUrls,
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
                    'pdfUrls': pdfUrls,
                    'imageUrls': imageUrls,
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
