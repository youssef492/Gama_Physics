import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/stage.dart';
import '../../services/announcement_seen_service.dart';
import '../../widgets/language_toggle.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _hasUnseen = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<DataProvider>();
    data.listenToStages();
    data.listenToAnnouncements();
    // نشوف حالة الإعلانات بعد ما يتحملوا
    _checkUnseen();
  }

  Future<void> _checkUnseen() async {
    final data = context.read<DataProvider>();
    final dates = data.announcements.map((a) => a.createdAt).toList();
    final result = await AnnouncementSeenService.hasUnseenAnnouncements(dates);
    if (mounted) setState(() => _hasUnseen = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    // كل ما الإعلانات تتحدث نعيد الفحص
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUnseen());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gama Physics'),
        actions: [
          const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/student-profile'),
          ),
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
      body: Column(
        children: [
          // ─── Welcome Banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeStudent(auth.currentUser?.name ?? ''),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUser?.grade ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Announcements Card ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign,
                          color: AppTheme.primaryBlue, size: 26),
                    ),
                    // ─── النقطة الحمرا ────────────────────────────────────
                    if (_hasUnseen)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(
                      l10n.announcements,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // ─── عداد الإعلانات الجديدة ──────────────────────────
                    if (_hasUnseen && data.announcements.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _NewBadge(count: _unseenCount(data)),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  // نمسح النقطة فوراً قبل ما ندخل الشاشة
                  setState(() => _hasUnseen = false);
                  await AnnouncementSeenService.markAsSeen();
                  if (mounted) {
                    Navigator.pushNamed(context, '/student-announcements');
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Stages Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.school, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.stages,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── Stages List ─────────────────────────────────────────────────
          Expanded(
            child: data.stages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox,
                            size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(l10n.noStages,
                            style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.stages.length,
                    itemBuilder: (context, index) {
                      final stage = data.stages[index];
                      return _buildStageCard(context, stage, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// عدد الإعلانات الجديدة (اللي بعد آخر زيارة)
  /// بيُحسب من الـ cache المحلي عشان مش هيعمل async هنا
  int _unseenCount(DataProvider data) {
    // نرجع عدد بسيط → لو أكتر من 9 نظهر "9+"
    // بما إننا مش عندنا lastSeen sync هنا نرجع بس 1 كـ indicator
    return data.announcements.length;
  }

  Widget _buildStageCard(BuildContext context, Stage stage, int index) {
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF06BEB6), const Color(0xFF48B1BF)],
      [const Color(0xFFEB3349), const Color(0xFFF45C43)],
    ];
    final gradientColors = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/student-semesters',
            arguments: {'stageId': stage.id, 'stageName': stage.name},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withAlpha(20),
                gradientColors[1].withAlpha(10),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.menu_book, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stage.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: gradientColors[0]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New Badge Widget ─────────────────────────────────────────────────────────
class _NewBadge extends StatelessWidget {
  final int count;
  const _NewBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'NEW',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
