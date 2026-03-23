import 'package:flutter/material.dart';
import 'package:GAMA/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/language_toggle.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final data = context.read<DataProvider>();
    data.listenToStages();
    data.listenToStudents();
    data.listenToAllCodes();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.controlPanel),
        actions: [
          const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.deepNavy, AppTheme.darkBlue]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 ${l10n.welcomeTeacher}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.currentUser?.name ?? '',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withAlpha(200)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statCard(l10n.stages, '${data.stages.length}',
                      Icons.school, const Color(0xFF667EEA)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(l10n.students, '${data.students.length}',
                      Icons.people, const Color(0xFF06BEB6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(l10n.codes, '${data.codes.length}',
                      Icons.vpn_key, const Color(0xFFEB3349)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              l10n.manageLessons,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _actionTile(
              l10n.manageStages,
              l10n.addStage,
              Icons.school,
              const Color(0xFF667EEA),
              () => Navigator.pushNamed(context, '/teacher-stages'),
            ),
            _actionTile(
              l10n.manageCodes,
              l10n.generateCodes,
              Icons.vpn_key,
              const Color(0xFFEB3349),
              () => Navigator.pushNamed(context, '/teacher-codes'),
            ),
            _actionTile(
              l10n.manageStudents,
              l10n.students,
              Icons.people,
              const Color(0xFF06BEB6),
              () => Navigator.pushNamed(context, '/teacher-students'),
            ),
            _actionTile(
              l10n.attendance,
              l10n.takeAttendance,
              Icons.fact_check,
              const Color(0xFFF5A623),
              () => Navigator.pushNamed(context, '/teacher-attendance'),
            ),
            _actionTile(
              l10n.announcements,
              l10n.newAnnouncement,
              Icons.campaign,
              const Color(0xFF9B51E0),
              () => Navigator.pushNamed(context, '/teacher-announcements'),
            ),
            const SizedBox(height: 24),
            // Center(
            //   child: OutlinedButton.icon(
            //     onPressed: () async {
            //       try {
            //         final seedService = SeedService();
            //         await seedService.seedData();
            //         if (mounted) {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //               SnackBar(content: Text(l10n.testDataSuccess)));
            //         }
            //       } catch (e) {
            //         if (mounted) {
            //           ScaffoldMessenger.of(context)
            //               .showSnackBar(SnackBar(content: Text(e.toString())));
            //         }
            //       }
            //     },
            //     icon: const Icon(Icons.data_array),
            //     label: Text(l10n.testData),
            //     style: OutlinedButton.styleFrom(
            //         foregroundColor: AppTheme.textMuted),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}
