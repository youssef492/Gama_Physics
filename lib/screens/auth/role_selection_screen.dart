import 'package:GAMA/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/language_toggle.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepNavy,
              AppTheme.darkBlue,
              AppTheme.primaryBlue
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language toggle top right
              Positioned(
                top: 8,
                right: 8,
                child: const LanguageToggle(),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/GAMA.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'GAMA',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const Text(
                        'PHYSICS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.physicsDesc,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/student-login'),
                          icon: const Icon(Icons.school, size: 24),
                          label: Text(
                            l10n.iAmStudent,
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/teacher-login'),
                          icon: const Icon(Icons.person, size: 24),
                          label: Text(
                            l10n.iAmTeacher,
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white54, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        l10n.copyright,
                        style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
