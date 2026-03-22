import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gama_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/language_provider.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GamaApp());
}

class GamaApp extends StatelessWidget {
  const GamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<AuthProvider, LanguageProvider>(
        builder: (context, auth, lang, _) {
          return MaterialApp(
            title: 'Gama Physics',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(isArabic: lang.isArabic),
            locale: lang.locale,
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routes: AppRoutes.routes,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return Scaffold(
        backgroundColor: AppTheme.deepNavy,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppTheme.accentCyan),
              SizedBox(height: 16),
              Text(
                'GAMA PHYSICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) return const RoleSelectionScreen();
    if (auth.isTeacher) return const TeacherDashboardScreen();
    if (auth.isStudent) return const StudentHomeScreen();
    return const RoleSelectionScreen();
  }
}
