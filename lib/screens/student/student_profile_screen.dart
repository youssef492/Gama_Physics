import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/language_toggle.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _isChangingGrade = false;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    // حمّل الـ stages علشان الـ dropdown
    context.read<DataProvider>().listenToStages();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Change Password ──────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_newPasswordController.text.length < 6) {
      _showSnackBar(l10n.passwordTooShort);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar(l10n.passwordMismatch);
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(_newPasswordController.text);

    if (!mounted) return;
    if (success) {
      _showSnackBar(l10n.passwordChangeSuccess, success: true);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _isChangingPassword = false);
    } else if (auth.error != null) {
      _showSnackBar(auth.error!);
    }
  }

  // ─── Change Grade ─────────────────────────────────────────────────────────
  Future<void> _changeGrade() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedGrade == null) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateGrade(_selectedGrade!);

    if (!mounted) return;
    if (success) {
      _showSnackBar(l10n.gradeUpdateSuccess, success: true);
      setState(() => _isChangingGrade = false);
    } else if (auth.error != null) {
      _showSnackBar(auth.error!);
    }
  }

  void _showSnackBar(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.successGreen : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final grades = data.stages.map((s) => s.name).toList();

    // init selected grade من current user
    if (_selectedGrade == null && user?.grade != null) {
      _selectedGrade = user!.grade;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: const [LanguageToggle()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Avatar ───────────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.darkBlue]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(user?.grade ?? '',
                style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 24),

            // ─── Info tiles ───────────────────────────────────
            _infoTile(Icons.phone, l10n.phoneNumber, user?.phone ?? ''),
            _infoTile(Icons.school, l10n.stage, user?.grade ?? ''),
            const SizedBox(height: 24),

            // ─── Change Grade card ────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _isChangingGrade = !_isChangingGrade),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          const Icon(Icons.school, color: AppTheme.accentCyan),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.changeGrade,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          Icon(_isChangingGrade
                              ? Icons.expand_less
                              : Icons.expand_more),
                        ],
                      ),
                    ),
                    if (_isChangingGrade) ...[
                      const Divider(height: 24),
                      grades.isEmpty
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text(l10n.loading,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted)),
                              ],
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: grades.contains(_selectedGrade)
                                  ? _selectedGrade
                                  : grades.first,
                              decoration: InputDecoration(
                                labelText: l10n.stage,
                                prefixIcon: const Icon(Icons.grade),
                              ),
                              isExpanded: true,
                              items: grades
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedGrade = v),
                            ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: (auth.isLoading ||
                                _selectedGrade == null ||
                                _selectedGrade == user?.grade)
                            ? null
                            : _changeGrade,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.save),
                      ),
                      // hint لو نفس المرحلة الحالية
                      if (_selectedGrade == user?.grade) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.gradeAlreadyCurrent,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Change Password card ─────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(
                          () => _isChangingPassword = !_isChangingPassword),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.changePassword,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          Icon(_isChangingPassword
                              ? Icons.expand_less
                              : Icons.expand_more),
                        ],
                      ),
                    ),
                    if (_isChangingPassword) ...[
                      const Divider(height: 24),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.newPassword),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.confirmNewPassword),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _changePassword,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.savePassword),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}
