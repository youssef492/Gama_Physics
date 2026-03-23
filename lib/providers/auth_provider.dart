import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/student_local_cache_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isStudent => _currentUser?.isStudent ?? false;
  bool get isTeacher => _currentUser?.isTeacher ?? false;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser != null) {
      try {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      } catch (_) {
        // لو النت فصل، نحاول نرجّع بيانات الطالب من الكاش المحلي.
        _currentUser = await StudentLocalCacheService.loadStudent();
      }

      // لو Firestore رجع null (مش موجود/Offline)، كمان جرّب الكاش.
      _currentUser ??= await StudentLocalCacheService.loadStudent();
    }

    // لو الكاش فيه بيانات طالب معطّل، اعتبره غير مسجل.
    if (_currentUser != null && _currentUser!.isDisabled) {
      _currentUser = null;
    }
    _initialized = true;
    notifyListeners();
  }

  // ─── Generate & save student code if missing ─────────────────────────────
  Future<void> generateAndSaveStudentCode() async {
    if (_currentUser == null) return;
    if (_currentUser!.studentCode.isNotEmpty) return;

    final code = _generateCode();
    try {
      await _authService.saveStudentCode(_currentUser!.uid, code);
      _currentUser = _currentUser!.copyWith(studentCode: code);
      await StudentLocalCacheService.saveStudent(_currentUser!);
      notifyListeners();
    } catch (e) {
      _error = 'تعذر حفظ كود الطالب (جرّب مرة أخرى).';
      notifyListeners();
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'GM-$code';
  }

  // ===== STUDENT AUTH =====

  Future<bool> signInStudent({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInStudent(
        phone: phone,
        password: password,
      );

      _currentUser = await _authService.getUserData(credential.user!.uid);

      if (_currentUser == null) {
        _error = 'لم يتم العثور على بيانات الحساب';
        await _authService.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_currentUser!.isDisabled) {
        _error = 'تم تعطيل حسابك. تواصل مع المدرس.';
        await _authService.signOut();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // احفظ بيانات الطالب محلياً علشان لو النت فصل نقدر نعرض QR والبيانات.
      await StudentLocalCacheService.saveStudent(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'رقم الهاتف غير مسجل';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _error = 'كلمة المرور غير صحيحة';
          break;
        default:
          _error = 'حدث خطأ: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerStudent({
    required String name,
    required String phone,
    required String password,
    required String grade,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.registerStudent(
        name: name,
        phone: phone,
        password: password,
        grade: grade,
      );

      if (_currentUser != null) {
        await StudentLocalCacheService.saveStudent(_currentUser!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'رقم الهاتف مسجل بالفعل';
          break;
        case 'weak-password':
          _error = 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
          break;
        default:
          _error = 'حدث خطأ: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===== TEACHER AUTH =====

  Future<bool> signInTeacher({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInTeacher(
        email: email,
        password: password,
      );

      _currentUser = await _authService.getUserData(credential.user!.uid);

      if (_currentUser == null || !_currentUser!.isTeacher) {
        _error = 'هذا الحساب ليس حساب مدرس';
        await _authService.signOut();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'البريد الإلكتروني غير مسجل';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _error = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          _error = 'البريد الإلكتروني غير صالح';
          break;
        default:
          _error = 'حدث خطأ: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===== CHANGE PASSWORD =====

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.changeStudentPassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'حدث خطأ أثناء تغيير كلمة المرور';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===== SIGN OUT =====

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // ===== UPDATE GRADE =====

  Future<bool> updateGrade(String newGrade) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUserGrade(_currentUser!.uid, newGrade);
      _currentUser = _currentUser!.copyWith(grade: newGrade);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
