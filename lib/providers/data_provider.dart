import 'package:flutter/material.dart';
import '../models/stage.dart';
import '../models/semester.dart';
import '../models/lesson.dart';
import '../models/access_code.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

class DataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Stage> _stages = [];
  List<Semester> _semesters = [];
  List<Lesson> _lessons = [];
  List<Lesson> _allPaidLessons = [];
  List<AccessCode> _codes = [];
  List<AppUser> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Stage> get stages => _stages;
  List<Semester> get semesters => _semesters;
  List<Lesson> get lessons => _lessons;
  List<Lesson> get allPaidLessons => _allPaidLessons;
  List<AccessCode> get codes => _codes;
  List<AppUser> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> deleteStudent(String uid) async {
    try {
      await _firestoreService.deleteStudent(uid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== STAGES =====

  void listenToStages() {
    _firestoreService.getStages().listen((stages) {
      _stages = stages;
      notifyListeners();
    });
  }

  Future<void> addStage(String name, int order) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addStage(name, order);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStage(String id, String name, int order) async {
    try {
      await _firestoreService.updateStage(id, name, order);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteStage(String id) async {
    try {
      await _firestoreService.deleteStage(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== SEMESTERS =====

  void listenToSemesters(String stageId) {
    _firestoreService.getSemesters(stageId).listen((semesters) {
      _semesters = semesters;
      notifyListeners();
    });
  }

  Future<void> addSemester(String stageId, String name, int order) async {
    try {
      await _firestoreService.addSemester(stageId, name, order);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSemester(String id, String name, int order) async {
    try {
      await _firestoreService.updateSemester(id, name, order);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSemester(String id) async {
    try {
      await _firestoreService.deleteSemester(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== LESSONS =====

  void listenToLessons(String semesterId) {
    _firestoreService.getLessons(semesterId).listen((lessons) {
      _lessons = lessons;
      notifyListeners();
    });
  }

  void listenToVisibleLessons(String semesterId) {
    _firestoreService.getVisibleLessons(semesterId).listen((lessons) {
      _lessons = lessons;
      notifyListeners();
    });
  }

  /// للاستخدام في generate codes - بيجيب كل الدروس المدفوعة بغض النظر عن الـ semester
  void listenToAllPaidLessons() {
    _firestoreService.getAllPaidLessons().listen((lessons) {
      _allPaidLessons = lessons;
      notifyListeners();
    });
  }

  Future<void> addLesson(Lesson lesson) async {
    try {
      await _firestoreService.addLesson(lesson);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateLesson(id, data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLessonVisibility(String id, bool isVisible) async {
    try {
      await _firestoreService.toggleLessonVisibility(id, isVisible);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await _firestoreService.deleteLesson(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== ACCESS CODES =====

  void listenToCodesForLesson(String lessonId) {
    _firestoreService.getCodesForLesson(lessonId).listen((codes) {
      _codes = codes;
      notifyListeners();
    });
  }

  void listenToAllCodes() {
    _firestoreService.getAllCodes().listen((codes) {
      _codes = codes;
      notifyListeners();
    });
  }

  Future<void> addCode(AccessCode code) async {
    try {
      await _firestoreService.addCode(code);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> disableCode(String id) async {
    try {
      await _firestoreService.disableCode(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> enableCode(String id) async {
    try {
      await _firestoreService.enableCode(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// تعديل تاريخ انتهاء كود واحد
  Future<void> updateCodeExpiry(String id, DateTime? newExpiry) async {
    try {
      await _firestoreService.updateCodeExpiry(id, newExpiry);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// تعديل تاريخ انتهاء كل أكواد درس — يرجع عدد الأكواد اللي اتعدلت
  Future<int> bulkUpdateExpiryByLesson(
      String lessonId, DateTime? newExpiry) async {
    try {
      return await _firestoreService.bulkUpdateExpiryByLesson(
          lessonId, newExpiry);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // ===== STUDENTS =====

  void listenToStudents() {
    _firestoreService.getStudents().listen((students) {
      _students = students;
      notifyListeners();
    });
  }

  Future<void> toggleStudentDisabled(String uid, bool isDisabled) async {
    try {
      await _firestoreService.toggleStudentDisabled(uid, isDisabled);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateStudentGrade(String uid, String newGrade) async {
    try {
      await _firestoreService.updateStudentGrade(uid, newGrade);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<AccessCode>> getCodesUsedByStudent(String studentId) async {
    try {
      return await _firestoreService.getCodesUsedByStudent(studentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
}
