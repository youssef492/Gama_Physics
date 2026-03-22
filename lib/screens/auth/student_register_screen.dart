import 'package:flutter/material.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_overlay.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGrade;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // حمّل الـ stages علشان يبان في الـ dropdown
    context.read<DataProvider>().listenToStages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(List<String> grades) async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.enterName)));
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.phoneNumber)));
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.passwordTooShort)));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.passwordMismatch)));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerStudent(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      grade: _selectedGrade ?? (grades.isNotEmpty ? grades.first : ''),
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/student-home', (route) => false);
    } else if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authProvider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();

    // حوّل الـ stages لـ list of strings، fallback لو لسه بتتحمل
    final grades = data.stages.map((s) => s.name).toList();
    if (grades.isNotEmpty &&
        (_selectedGrade == null || !grades.contains(_selectedGrade))) {
      // اعمل ده outside build مش هنا - بس هنا safe لأنه بيحصل مرة واحدة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_selectedGrade == null || !grades.contains(_selectedGrade))) {
          setState(() => _selectedGrade = grades.first);
        }
      });
    }

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.newStudent),
          backgroundColor: AppTheme.primaryBlue,
          actions: const [LanguageToggle()],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add,
                      size: 64, color: AppTheme.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    l10n.createAccount,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      hintText: '01xxxxxxxxx',
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stage dropdown - بيتحمل من Firestore
                  if (grades.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.loading,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGrade,
                      decoration: InputDecoration(
                        labelText: l10n.stage,
                        prefixIcon: const Icon(Icons.grade),
                      ),
                      isExpanded: true,
                      items: grades.map((grade) {
                        return DropdownMenuItem(
                            value: grade, child: Text(grade));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGrade = value),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: grades.isEmpty ? null : () => _register(grades),
                    child: Text(l10n.createAccountBtn),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.haveAccount),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.login),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
