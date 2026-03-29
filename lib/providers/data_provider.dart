import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/stage.dart';
import '../models/semester.dart';
import '../models/lesson.dart';
import '../models/access_code.dart';
import '../models/app_user.dart';
import '../models/announcement.dart';
import '../services/firestore_service.dart';

enum DataError { none, offline, permissionDenied, unknown }

class DataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Stage> _stages = [];
  List<Semester> _semesters = [];
  List<Lesson> _lessons = [];
  List<Lesson> _allPaidLessons = [];
  List<AccessCode> _codes = [];
  List<AppUser> _students = [];
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  DataError _dataError = DataError.none;

  StreamSubscription<List<Stage>>? _stagesSub;
  StreamSubscription<List<Semester>>? _semestersSub;
  StreamSubscription<List<Lesson>>? _lessonsSub;
  StreamSubscription<List<Lesson>>? _paidLessonsSub;
  StreamSubscription<List<AccessCode>>? _codesSub;
  StreamSubscription<List<AppUser>>? _studentsSub;
  StreamSubscription<List<Announcement>>? _announcementsSub;

  List<Stage> get stages => _stages;
  List<Semester> get semesters => _semesters;
  List<Lesson> get lessons => _lessons;
  List<Lesson> get allPaidLessons => _allPaidLessons;
  List<AccessCode> get codes => _codes;
  List<AppUser> get students => _students;
  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  DataError get dataError => _dataError;
  bool get isOffline => _dataError == DataError.offline;

  // backward compat
  String? get error => _dataError == DataError.none ? null : _errorMessage;
  String get _errorMessage {
    switch (_dataError) {
      case DataError.offline:
        return 'لا يوجد اتصال بالإنترنت';
      case DataError.permissionDenied:
        return '';
      case DataError.unknown:
        return 'حدث خطأ، يرجى المحاولة مرة أخرى';
      case DataError.none:
        return '';
    }
  }

  void clearError() {
    _dataError = DataError.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _stagesSub?.cancel();
    _semestersSub?.cancel();
    _lessonsSub?.cancel();
    _paidLessonsSub?.cancel();
    _codesSub?.cancel();
    _studentsSub?.cancel();
    _announcementsSub?.cancel();
    super.dispose();
  }

  // ─── مركزي لمعالجة الأخطاء ────────────────────────────────────────────────
  void _handleError(dynamic e, {bool silent = false}) {
    if (e is FirebaseException) {
      if (e.code == 'permission-denied' || e.code == 'PERMISSION_DENIED') {
        // نتجاهله تماماً — بيحصل أول تشغيل قبل ما الـ auth يكتمل
        if (!silent) debugPrint('[DataProvider] permission-denied silenced');
        return; // مش بنغير الـ state خالص
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        _dataError = DataError.offline;
        notifyListeners();
        return;
      }
    }
    if (e is SocketException || e is TimeoutException) {
      _dataError = DataError.offline;
      notifyListeners();
      return;
    }
    if (!silent) debugPrint('[DataProvider] unhandled: $e');
  }

  // ─── ANNOUNCEMENTS ─────────────────────────────────────────────────────────
  void listenToAnnouncements() {
    _announcementsSub?.cancel();
    _announcementsSub = _firestoreService.getAnnouncements().listen(
      (list) {
        _announcements = list;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  Future<void> addAnnouncement(Announcement a) async {
    try {
      await _firestoreService.addAnnouncement(a);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateAnnouncement(
      String id, String title, String content, String? pdfUrl) async {
    try {
      await _firestoreService.updateAnnouncement(id, title, content, pdfUrl: pdfUrl);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestoreService.deleteAnnouncement(id);
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── STAGES ────────────────────────────────────────────────────────────────
  void listenToStages() {
    _stagesSub?.cancel();
    _isLoading = true;
    _stagesSub = _firestoreService.getStages().listen(
      (stages) {
        _stages = stages;
        _isLoading = false;
        if (_dataError != DataError.none) _dataError = DataError.none;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _handleError(e, silent: true);
      },
      cancelOnError: false,
    );
  }

  Future<void> addStage(String name, int order) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addStage(name, order);
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStage(String id, String name, int order) async {
    try {
      await _firestoreService.updateStage(id, name, order);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteStage(String id) async {
    try {
      await _firestoreService.deleteStage(id);
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── SEMESTERS ─────────────────────────────────────────────────────────────
  void listenToSemesters(String stageId) {
    _semestersSub?.cancel();
    _semestersSub = _firestoreService.getSemesters(stageId).listen(
      (list) {
        _semesters = list;
        if (_dataError != DataError.none) _dataError = DataError.none;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  Future<void> addSemester(String stageId, String name, int order) async {
    try {
      await _firestoreService.addSemester(stageId, name, order);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateSemester(String id, String name, int order) async {
    try {
      await _firestoreService.updateSemester(id, name, order);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteSemester(String id) async {
    try {
      await _firestoreService.deleteSemester(id);
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── LESSONS ───────────────────────────────────────────────────────────────
  void listenToLessons(String semesterId) {
    _lessonsSub?.cancel();
    _lessonsSub = _firestoreService.getLessons(semesterId).listen(
      (list) {
        _lessons = list;
        if (_dataError != DataError.none) _dataError = DataError.none;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  void listenToVisibleLessons(String semesterId) {
    _lessonsSub?.cancel();
    _lessonsSub = _firestoreService.getVisibleLessons(semesterId).listen(
      (list) {
        _lessons = list;
        if (_dataError != DataError.none) _dataError = DataError.none;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  void listenToAllPaidLessons() {
    _paidLessonsSub?.cancel();
    _paidLessonsSub = _firestoreService.getAllPaidLessons().listen(
      (list) {
        _allPaidLessons = list;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  Future<void> addLesson(Lesson lesson) async {
    try {
      await _firestoreService.addLesson(lesson);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateLesson(id, data);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> toggleLessonVisibility(String id, bool isVisible) async {
    try {
      await _firestoreService.toggleLessonVisibility(id, isVisible);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await _firestoreService.deleteLesson(id);
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── ACCESS CODES ──────────────────────────────────────────────────────────
  void listenToCodesForLesson(String lessonId) {
    _codesSub?.cancel();
    _codesSub = _firestoreService.getCodesForLesson(lessonId).listen(
      (list) {
        _codes = list;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  void listenToAllCodes() {
    _codesSub?.cancel();
    _codesSub = _firestoreService.getAllCodes().listen(
      (list) {
        _codes = list;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  Future<void> addCode(AccessCode code) async {
    try {
      await _firestoreService.addCode(code);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> validateAndUseCode({
    required String code,
    required String lessonId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      return await _firestoreService.validateAndUseCode(
        codeString: code,
        lessonId: lessonId,
        studentId: studentId,
        studentName: studentName,
      );
    } catch (e) {
      if (e.toString().contains('used_by_another_student')) {
        rethrow;
      }
      _handleError(e);
      return false;
    }
  }

  Future<void> disableCode(String id) async {
    try {
      await _firestoreService.disableCode(id);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> enableCode(String id) async {
    try {
      await _firestoreService.enableCode(id);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateCodeExpiry(String id, DateTime? newExpiry) async {
    try {
      await _firestoreService.updateCodeExpiry(id, newExpiry);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<int> bulkUpdateExpiryByLesson(
      String lessonId, DateTime? newExpiry) async {
    try {
      return await _firestoreService.bulkUpdateExpiryByLesson(
          lessonId, newExpiry);
    } catch (e) {
      _handleError(e);
      return 0;
    }
  }

  // ─── STUDENTS ──────────────────────────────────────────────────────────────
  void listenToStudents() {
    _studentsSub?.cancel();
    _studentsSub = _firestoreService.getStudents().listen(
      (list) {
        _students = list;
        notifyListeners();
      },
      onError: (e) => _handleError(e, silent: true),
      cancelOnError: false,
    );
  }

  Future<void> toggleStudentDisabled(String uid, bool isDisabled) async {
    try {
      await _firestoreService.toggleStudentDisabled(uid, isDisabled);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateStudentGrade(String uid, String newGrade) async {
    try {
      await _firestoreService.updateStudentGrade(uid, newGrade);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<List<AccessCode>> getCodesUsedByStudent(String studentId) async {
    try {
      return await _firestoreService.getCodesUsedByStudent(studentId);
    } catch (e) {
      _handleError(e, silent: true);
      return [];
    }
  }

  Future<void> deleteStudent(String uid) async {
    try {
      await _firestoreService.deleteStudent(uid);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<int> deleteCodesByLesson(String lessonId) async {
    try {
      return await _firestoreService.deleteCodesByLesson(lessonId);
    } catch (e) {
      _handleError(e);
      return 0;
    }
  }

  Future<void> deleteCode(String id) => _firestoreService.deleteCode(id);

  Future<void> updateCodeMaxUses(String id, int newMaxUses) =>
      _firestoreService.updateCodeMaxUses(id, newMaxUses);
}
