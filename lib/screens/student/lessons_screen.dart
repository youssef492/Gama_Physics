import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/code_entry_dialog.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  String? semesterId;
  String? semesterName;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      semesterId = args['semesterId'] as String;
      semesterName = args['semesterName'] as String;
      context.read<DataProvider>().listenToVisibleLessons(semesterId!);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(semesterName ?? l10n.lessons)),
      body: _buildBody(context, l10n, data, auth),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n,
      DataProvider data, AuthProvider auth) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.loadingLessons),
          ],
        ),
      );
    }

    if (data.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(data.error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                data.clearError();
                data.listenToVisibleLessons(semesterId!);
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (data.lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(l10n.noLessons, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: data.lessons.length,
      itemBuilder: (context, index) {
        final lesson = data.lessons[index];
        return LessonCard(
          lesson: lesson,
          onTap: () {
            if (lesson.isFree) {
              Navigator.pushNamed(context, '/student-lesson-detail',
                  arguments: lesson);
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CodeEntryDialog(
                  lessonTitle: lesson.title,
                  onSubmit: (code) async {
                    final valid = await data.validateAndUseCode(
                      code: code,
                      lessonId: lesson.id,
                      studentId: auth.currentUser!.uid,
                      studentName: auth.currentUser!.name,
                    );
                    if (valid && context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/student-lesson-detail',
                          arguments: lesson);
                    } else if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.invalidCode)),
                      );
                    }
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}
