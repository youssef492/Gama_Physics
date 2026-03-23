import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';

class ManageStagesScreen extends StatelessWidget {
  const ManageStagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageStages)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, data),
        child: const Icon(Icons.add),
      ),
      body: data.stages.isEmpty
          ? Center(
              child: Text(l10n.noStages,
                  style: const TextStyle(color: AppTheme.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.stages.length,
              itemBuilder: (context, index) {
                final stage = data.stages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text('${stage.order}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(stage.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.folder_open,
                              color: AppTheme.primaryBlue),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/teacher-semesters',
                            arguments: {
                              'stageId': stage.id,
                              'stageName': stage.name
                            },
                          ),
                          tooltip: l10n.semesters,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: AppTheme.warningOrange),
                          onPressed: () => _showAddEditDialog(context, data,
                              id: stage.id,
                              name: stage.name,
                              order: stage.order),
                          tooltip: l10n.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppTheme.errorRed),
                          onPressed: () => _confirmDelete(
                              context, data, stage.id, stage.name),
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
        text: (order ?? data.stages.length + 1).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? l10n.addStage : l10n.editStage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.stageName),
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
                await data.addStage(n, o);
              } else {
                await data.updateStage(id, n, o);
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
              await data.deleteStage(id);
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
