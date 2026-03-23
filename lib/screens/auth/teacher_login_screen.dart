import 'package:flutter/material.dart';
import 'package:GAMA/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_overlay.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.enterEmail)));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInTeacher(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/teacher-dashboard', (route) => false);
    } else if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authProvider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return LoadingOverlay(
          isLoading: auth.isLoading,
          message: l10n.loading,
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.deepNavy, AppTheme.darkBlue],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(top: 8, right: 8, child: const LanguageToggle()),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_ios,
                                      color: Colors.white70),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.admin_panel_settings,
                                    size: 60, color: AppTheme.accentCyan),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.teacherPanel,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.loginToPanel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(180),
                                ),
                              ),
                              const SizedBox(height: 40),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  labelStyle: TextStyle(
                                      color: Colors.white.withAlpha(180)),
                                  prefixIcon: Icon(Icons.email,
                                      color: Colors.white.withAlpha(180)),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(25),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.white.withAlpha(50)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppTheme.accentCyan, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  labelStyle: TextStyle(
                                      color: Colors.white.withAlpha(180)),
                                  prefixIcon: Icon(Icons.lock,
                                      color: Colors.white.withAlpha(180)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white.withAlpha(180),
                                    ),
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(25),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.white.withAlpha(50)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppTheme.accentCyan, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentCyan,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(l10n.login,
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
