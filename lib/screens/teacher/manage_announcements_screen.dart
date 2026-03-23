import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/announcement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import 'package:intl/intl.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DataProvider>().listenToAnnouncements();
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.newAnnouncement),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n.announcementTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.announcementContent,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          contentController.text.trim().isEmpty) {
                        return;
                      }
                      setS(() => isLoading = true);
                      final author =
                          context.read<AuthProvider>().currentUser?.name ?? '';
                      final announcement = Announcement(
                        id: const Uuid().v4(),
                        title: titleController.text.trim(),
                        content: contentController.text.trim(),
                        createdAt: DateTime.now(),
                        authorName: author,
                      );

                      await context
                          .read<DataProvider>()
                          .addAnnouncement(announcement);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.announcementAdded),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnouncement(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteAnnouncementConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        await context.read<DataProvider>().deleteAnnouncement(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.announcementDeleted)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final DateFormat formatter = DateFormat('yyyy/MM/dd hh:mm a');
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.announcements),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: data.announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(l10n.noAnnouncements,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.announcements.length,
              itemBuilder: (context, index) {
                final ann = data.announcements[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ann.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppTheme.errorRed),
                              onPressed: () => _deleteAnnouncement(ann.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ann.content,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ann.authorName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              formatter.format(ann.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
