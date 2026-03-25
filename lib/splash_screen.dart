import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/student/student_profile_screen.dart';
import '../../screens/student/student_home_screen.dart';
import '../../screens/teacher/teacher_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Animation Controllers ─────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _lineController;
  late final AnimationController _subtitleController;
  late final AnimationController _pulseController;

  // ─── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _lineWidth;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _pulseScale;

  // ─── State ─────────────────────────────────────────────────────────────────
  _SplashState _state = _SplashState.loading;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();
    _lineController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _subtitleController.forward();

    await Future.wait([
      _checkConnectivityAndAuth(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
  }

  // ─── Connectivity check (محسّن لـ Windows + iOS + Android) ────────────────
  Future<bool> _checkConnectivity() async {
    // على Windows نستخدم HTTP request بدل DNS lookup
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return await _checkConnectivityHttp();
    }

    // Android & iOS: نجرب DNS أولاً، لو فشل نجرب HTTP
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException {
      // فشل DNS → نجرب HTTP
    } on TimeoutException {
      // timeout DNS → نجرب HTTP
    } catch (_) {
      // أي خطأ تاني → نجرب HTTP
    }

    // Fallback: HTTP request
    return await _checkConnectivityHttp();
  }

  Future<bool> _checkConnectivityHttp() async {
    // قائمة من الـ endpoints نجرب فيها بالترتيب
    const endpoints = [
      'https://www.google.com',
      'https://www.gstatic.com/generate_204',
      'https://connectivity-check.ubuntu.com',
    ];

    for (final url in endpoints) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 5);
        final req = await client
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        req.headers.set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 GamaPhysics/1.0',
        );
        final res = await req.close().timeout(const Duration(seconds: 6));
        await res.drain();
        client.close();
        // أي status code يعني في نت (حتى 204 أو 301)
        if (res.statusCode < 500) return true;
      } catch (_) {
        // جرب الـ endpoint الجاي
        continue;
      }
    }
    return false;
  }

  Future<void> _checkConnectivityAndAuth() async {
    final bool isOnline = await _checkConnectivity();

    if (!isOnline) {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      // انتظر AuthProvider يخلص initialize لو لسه
      if (!auth.initialized) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return !auth.initialized;
        }).timeout(const Duration(seconds: 3), onTimeout: () {});
      }

      if (!mounted) return;

      // لو الطالب عنده cached session → روحه للـ profile عشان يشوف QR
      if (auth.isAuthenticated && auth.isStudent) {
        _navigate(auth, studentToProfile: true);
        return;
      }

      setState(() => _state = _SplashState.offline);
      return;
    }

    // ─── Online: تحقق من Auth ───────────────────────────────────────────────
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (!auth.initialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return !auth.initialized;
      }).timeout(const Duration(seconds: 10));
    }

    if (!mounted) return;
    _navigate(auth);
  }

  void _navigate(AuthProvider auth, {bool studentToProfile = false}) {
    if (!mounted) return;
    Widget destination;
    if (!auth.isAuthenticated) {
      destination = const RoleSelectionScreen();
    } else if (auth.isTeacher) {
      destination = const TeacherDashboardScreen();
    } else if (studentToProfile) {
      destination = const StudentProfileScreen();
    } else {
      destination = const StudentHomeScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _state = _SplashState.loading);
    await _checkConnectivityAndAuth();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _lineController.dispose();
    _subtitleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: Stack(
        children: [
          // ─── Background decorative circles ─────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withAlpha(25),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCyan.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withAlpha(20),
              ),
            ),
          ),

          // ─── Main content ───────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ─── Logo ───────────────────────────────────────────────────
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_logoController, _pulseController]),
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value *
                          (_state == _SplashState.loading &&
                                  _logoController.isCompleted
                              ? _pulseScale.value
                              : 1.0),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentCyan.withAlpha(80),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/GAMA.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ─── GAMA text ─────────────────────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: const Text(
                      'GAMA',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 12,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Divider line ──────────────────────────────────────────
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (_, __) => SizedBox(
                    width: 180,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: _lineWidth.value,
                        child: Container(
                          height: 2,
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.accentCyan,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── PHYSICS subtitle ──────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: const Text(
                    'PHYSICS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 10,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ─── Bottom area: loader / offline ─────────────────────────
                SizedBox(
                  height: 120,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _state == _SplashState.offline
                        ? _OfflineWidget(onRetry: _retry)
                        : _LoadingIndicator(),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State enum ────────────────────────────────────────────────────────────────
enum _SplashState { loading, offline }

// ─── Loading indicator ─────────────────────────────────────────────────────────
class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.accentCyan.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

// ─── Offline widget ────────────────────────────────────────────────────────────
class _OfflineWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('offline'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.white60, size: 16),
              SizedBox(width: 8),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
