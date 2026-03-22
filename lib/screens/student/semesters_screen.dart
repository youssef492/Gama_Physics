import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';

class SemestersScreen extends StatefulWidget {
  const SemestersScreen({super.key});

  @override
  State<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends State<SemestersScreen> {
  String? stageId;
  String? stageName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && stageId == null) {
      stageId = args['stageId'] as String;
      stageName = args['stageName'] as String;
      context.read<DataProvider>().listenToSemesters(stageId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(stageName ?? l10n.semesters),
      ),
      body: data.semesters.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(l10n.noSemesters,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.semesters.length,
              itemBuilder: (context, index) {
                final semester = data.semesters[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    title: Text(semester.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 18, color: AppTheme.primaryBlue),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/student-lessons',
                        arguments: {
                          'stageId': stageId,
                          'semesterId': semester.id,
                          'semesterName': semester.name,
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
