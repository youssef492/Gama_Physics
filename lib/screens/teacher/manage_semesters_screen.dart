import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';

class ManageSemestersScreen extends StatefulWidget {
  const ManageSemestersScreen({super.key});

  @override
  State<ManageSemestersScreen> createState() => _ManageSemestersScreenState();
}

class _ManageSemestersScreenState extends State<ManageSemestersScreen> {
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
      appBar: AppBar(title: Text('${l10n.semesters}: ${stageName ?? ''}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, data),
        child: const Icon(Icons.add),
      ),
      body: data.semesters.isEmpty
          ? Center(
              child: Text(l10n.noSemesters,
                  style: const TextStyle(color: AppTheme.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.semesters.length,
              itemBuilder: (context, index) {
                final semester = data.semesters[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentCyan,
                      child: Text('${semester.order}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(semester.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.video_library,
                              color: AppTheme.primaryBlue),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/teacher-lessons',
                            arguments: {
                              'stageId': stageId,
                              'semesterId': semester.id,
                              'semesterName': semester.name,
                            },
                          ),
                          tooltip: l10n.lessons,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: AppTheme.warningOrange),
                          onPressed: () => _showAddEditDialog(context, data,
                              id: semester.id,
                              name: semester.name,
                              order: semester.order),
                          tooltip: l10n.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppTheme.errorRed),
                          onPressed: () => _confirmDelete(
                              context, data, semester.id, semester.name),
                          tooltip: l10n.delete,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddEditDialog(BuildContext context, DataProvider data,
      {String? id, String? name, int? order}) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: name ?? '');
    final orderController = TextEditingController(
        text: (order ?? data.semesters.length + 1).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? l10n.addSemester : l10n.editSemester),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.semesterName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.order),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final n = nameController.text.trim();
              final o = int.tryParse(orderController.text) ?? 1;
              if (n.isEmpty) return;
              if (id == null) {
                await data.addSemester(stageId!, n, o);
              } else {
                await data.updateSemester(id, n, o);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(id == null ? l10n.add : l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, DataProvider data, String id, String name) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text('${l10n.deleteStageConfirm} "$name"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await data.deleteSemester(id);
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
