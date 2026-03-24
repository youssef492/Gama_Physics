import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  bool _isGeneratingCode = false;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    context.read<DataProvider>().listenToStages();
    // لو الطالب مش عنده كود، ولّده تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureStudentCode());
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Ensure student has a code ───────────────────────────────────────────
  Future<void> _ensureStudentCode() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;
    if (auth.currentUser!.studentCode.isNotEmpty) return;

    // مش عنده كود → ولّد واحد
    setState(() => _isGeneratingCode = true);
    await auth.generateAndSaveStudentCode();
    if (mounted) setState(() => _isGeneratingCode = false);
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

  // ─── Show QR full screen dialog ───────────────────────────────────────────
  void _showQrDialog(BuildContext context, String uid, String code) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.qr_code_2,
                      color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.qrCode,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // QR Code large
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: uid,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Student Code
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.deepNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.studentCodeLabel,
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Copy button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(ctx);
                    _showSnackBar('تم نسخ الكود ✓', success: true);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.copy),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final grades = data.stages.map((s) => s.name).toList();

    if (_selectedGrade == null && user?.grade != null) {
      _selectedGrade = user!.grade;
    }

    final studentCode = user?.studentCode ?? '';
    final hasCode = studentCode.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: const [LanguageToggle()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
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

            // ── Info tiles ────────────────────────────────────────────────
            _infoTile(Icons.phone, l10n.phoneNumber, user?.phone ?? ''),
            _infoTile(Icons.school, l10n.stage, user?.grade ?? ''),
            const SizedBox(height: 16),

            // ── QR Code Card ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_2,
                            color: AppTheme.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.qrCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        if (_isGeneratingCode)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isGeneratingCode)
                       Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            l10n.generatingCode,
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    else if (hasCode) ...[
                      // QR preview + info
                      Row(
                        children: [
                          // QR preview
                          GestureDetector(
                            onTap: () =>
                                _showQrDialog(context, user.uid, studentCode),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: user!.uid,
                                version: QrVersions.auto,
                                size: 90,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Code info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'كود الطالب',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.deepNavy,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    studentCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showQrDialog(
                                            context, user.uid, studentCode),
                                        icon: const Icon(Icons.fullscreen,
                                            size: 16),
                                        label: Text(l10n.view,
                                            style: const TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryBlue,
                                          side: const BorderSide(
                                              color: AppTheme.primaryBlue),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: studentCode));
                                          _showSnackBar('تم نسخ الكود ✓',
                                              success: true);
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: Text(l10n.copy,
                                            style: const TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.accentCyan,
                                          side: const BorderSide(
                                              color: AppTheme.accentCyan),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // No code yet
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.qr_code,
                                size: 48,
                                color: AppTheme.textMuted.withAlpha(100)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noCodeYet,
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isGeneratingCode
                                  ? null
                                  : () async {
                                      setState(() => _isGeneratingCode = true);
                                      await auth.generateAndSaveStudentCode();
                                      if (mounted) {
                                        setState(
                                            () => _isGeneratingCode = false);
                                      }
                                    },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.generateCodes),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Change Grade card ─────────────────────────────────────────
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

            // ── Change Password card ──────────────────────────────────────
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
