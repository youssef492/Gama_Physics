import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stage.dart';
import '../models/semester.dart';
import '../models/lesson.dart';
import '../models/access_code.dart';
import '../models/app_user.dart';
import '../models/attendance_session.dart';
import '../models/announcement.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, String>> getLessonTitles(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return {};
    final Map<String, String> result = {};
    for (int i = 0; i < lessonIds.length; i += 10) {
      final batch = lessonIds.sublist(i, (i + 10).clamp(0, lessonIds.length));
      final snap = await _db
          .collection('lessons')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (var doc in snap.docs) {
        result[doc.id] = doc.data()['title'] ?? 'درس غير معروف';
      }
    }
    return result;
  }

  // ===== STAGES =====

  Stream<List<Stage>> getStages() {
    return _db
        .collection('stages')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Stage.fromSnapshot(d)).toList());
  }

  Future<Stage> addStage(String name, int order) async {
    final doc = await _db.collection('stages').add({
      'name': name,
      'order': order,
    });
    return Stage(id: doc.id, name: name, order: order);
  }

  Future<void> updateStage(String id, String name, int order) async {
    await _db.collection('stages').doc(id).update({
      'name': name,
      'order': order,
    });
  }

  Future<void> deleteStage(String id) async {
    final semesters =
        await _db.collection('semesters').where('stageId', isEqualTo: id).get();
    for (var sem in semesters.docs) {
      await _deleteSemesterCascade(sem.id);
    }
    await _db.collection('stages').doc(id).delete();
  }

  // ===== SEMESTERS =====

  Stream<List<Semester>> getSemesters(String stageId) {
    return _db
        .collection('semesters')
        .where('stageId', isEqualTo: stageId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Semester.fromSnapshot(d)).toList());
  }

  Future<Semester> addSemester(String stageId, String name, int order) async {
    final doc = await _db.collection('semesters').add({
      'stageId': stageId,
      'name': name,
      'order': order,
    });
    return Semester(id: doc.id, stageId: stageId, name: name, order: order);
  }

  Future<void> updateSemester(String id, String name, int order) async {
    await _db.collection('semesters').doc(id).update({
      'name': name,
      'order': order,
    });
  }

  Future<void> deleteSemester(String id) async {
    await _deleteSemesterCascade(id);
  }

  Future<void> _deleteSemesterCascade(String semId) async {
    final lessons = await _db
        .collection('lessons')
        .where('semesterId', isEqualTo: semId)
        .get();
    for (var lesson in lessons.docs) {
      final codes = await _db
          .collection('accessCodes')
          .where('lessonId', isEqualTo: lesson.id)
          .get();
      for (var code in codes.docs) {
        await code.reference.delete();
      }
      await lesson.reference.delete();
    }
    await _db.collection('semesters').doc(semId).delete();
  }

  // ===== LESSONS =====

  Stream<List<Lesson>> getVisibleLessons(String semesterId) {
    return _db
        .collection('lessons')
        .where('semesterId', isEqualTo: semesterId)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final lessons = snap.docs.map((d) => Lesson.fromSnapshot(d)).toList();
      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    });
  }

  Stream<List<Lesson>> getLessons(String semesterId) {
    return _db
        .collection('lessons')
        .where('semesterId', isEqualTo: semesterId)
        .snapshots()
        .map((snap) {
      final lessons = snap.docs.map((d) => Lesson.fromSnapshot(d)).toList();
      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    });
  }

  /// جيب كل الدروس المدفوعة (بدون تصفية semester) - للاستخدام في generate codes
  Stream<List<Lesson>> getAllPaidLessons() {
    return _db
        .collection('lessons')
        .where('lessonType', isEqualTo: 'paid')
        .snapshots()
        .map((snap) {
      final lessons = snap.docs.map((d) => Lesson.fromSnapshot(d)).toList();
      lessons.sort((a, b) => a.title.compareTo(b.title));
      return lessons;
    });
  }

  Future<Lesson> addLesson(Lesson lesson) async {
    final doc = await _db.collection('lessons').add(lesson.toMap());
    return Lesson.fromMap(doc.id, lesson.toMap());
  }

  Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    await _db.collection('lessons').doc(id).update(data);
  }

  Future<void> toggleLessonVisibility(String id, bool isVisible) async {
    await _db.collection('lessons').doc(id).update({'isVisible': isVisible});
  }

  Future<void> deleteLesson(String id) async {
    final codes = await _db
        .collection('accessCodes')
        .where('lessonId', isEqualTo: id)
        .get();
    for (var code in codes.docs) {
      await code.reference.delete();
    }
    await _db.collection('lessons').doc(id).delete();
  }

  // ===== ACCESS CODES =====

  Stream<List<AccessCode>> getCodesForLesson(String lessonId) {
    return _db
        .collection('accessCodes')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AccessCode.fromSnapshot(d)).toList());
  }

  Stream<List<AccessCode>> getAllCodes() {
    return _db
        .collection('accessCodes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AccessCode.fromSnapshot(d)).toList());
  }

  Future<AccessCode> addCode(AccessCode code) async {
    final doc = await _db.collection('accessCodes').add(code.toMap());
    return AccessCode.fromMap(doc.id, code.toMap());
  }

  Future<bool> validateAndUseCode({
    required String codeString,
    required String lessonId,
    required String studentId,
    required String studentName,
  }) async {
    final query = await _db
        .collection('accessCodes')
        .where('code', isEqualTo: codeString)
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    if (query.docs.isEmpty) return false;

    final doc = query.docs.first;
    final code = AccessCode.fromSnapshot(doc);

    if (code.status == 'disabled') return false;
    if (code.isExpired) return false;
    if (code.isFullyUsed) return false;

    final alreadyMine = code.usedBy.any((u) => u.studentId == studentId);

    // ✅ طالب تاني استخدمه قبل كده → مرفوض
    if (!alreadyMine && code.usedBy.isNotEmpty) return false;

    if (alreadyMine) {
      // ✅ نفس الطالب → زود currentUses بس
      await doc.reference.update({
        'currentUses': FieldValue.increment(1),
      });
    } else {
      // ✅ أول استخدام → أضف للـ usedBy وزود currentUses
      await doc.reference.update({
        'currentUses': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([
          {
            'studentId': studentId,
            'studentName': studentName,
            'usedAt': Timestamp.now(),
          }
        ]),
        'status': (code.currentUses + 1 >= code.maxUses) ? 'used' : 'active',
      });
    }

    return true;
  }

  Future<void> disableCode(String id) async {
    await _db.collection('accessCodes').doc(id).update({'status': 'disabled'});
  }

  Future<void> enableCode(String id) async {
    await _db.collection('accessCodes').doc(id).update({'status': 'active'});
  }

  /// تعديل تاريخ انتهاء كود واحد بالـ id
  Future<void> updateCodeExpiry(String id, DateTime? newExpiry) async {
    // نجيب الكود الحالي علشان نحدد الـ status الصح
    final doc = await _db.collection('accessCodes').doc(id).get();
    final code = AccessCode.fromSnapshot(doc);
    final isExpired = newExpiry != null && DateTime.now().isAfter(newExpiry);
    final newStatus = isExpired
        ? 'expired'
        : (code.status == 'expired' ? 'active' : code.status);
    await _db.collection('accessCodes').doc(id).update({
      'expiresAt': newExpiry != null ? Timestamp.fromDate(newExpiry) : null,
      'status': newStatus,
    });
  }

  /// Delete all codes for a specific lesson
  Future<int> deleteCodesByLesson(String lessonId) async {
    final snap = await _db
        .collection('accessCodes')
        .where('lessonId', isEqualTo: lessonId)
        .get();

    if (snap.docs.isEmpty) return 0;

    final batches = <WriteBatch>[];
    WriteBatch batch = _db.batch();
    int count = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;
      if (count % 499 == 0) {
        batches.add(batch);
        batch = _db.batch();
      }
    }
    batches.add(batch);
    for (final b in batches) await b.commit();

    return snap.docs.length;
  }

  /// تعديل تاريخ انتهاء كل أكواد درس معين دفعة واحدة (Batch Write)
  Future<int> bulkUpdateExpiryByLesson(
      String lessonId, DateTime? newExpiry) async {
    final snap = await _db
        .collection('accessCodes')
        .where('lessonId', isEqualTo: lessonId)
        .get();

    if (snap.docs.isEmpty) return 0;

    final isExpired = newExpiry != null && DateTime.now().isAfter(newExpiry);

    // Firestore batch max 500 writes
    final batches = <WriteBatch>[];
    WriteBatch batch = _db.batch();
    int count = 0;

    for (final doc in snap.docs) {
      final code = AccessCode.fromSnapshot(doc);
      final newStatus = isExpired
          ? 'expired'
          : (code.status == 'expired' ? 'active' : code.status);

      batch.update(doc.reference, {
        'expiresAt': newExpiry != null ? Timestamp.fromDate(newExpiry) : null,
        'status': newStatus,
      });
      count++;

      if (count % 499 == 0) {
        batches.add(batch);
        batch = _db.batch();
      }
    }
    batches.add(batch);

    for (final b in batches) {
      await b.commit();
    }

    return snap.docs.length;
  }

  // ===== USERS / STUDENTS =====

  Stream<List<AppUser>> getStudents() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => AppUser.fromMap(d.data())).toList());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> toggleStudentDisabled(String uid, bool isDisabled) async {
    await _db.collection('users').doc(uid).update({'isDisabled': isDisabled});
  }

  Future<void> updateStudentGrade(String uid, String newGrade) async {
    await _db.collection('users').doc(uid).update({'grade': newGrade});
  }

  Future<List<AccessCode>> getCodesUsedByStudent(String studentId) async {
    final query = await _db.collection('accessCodes').get();
    return query.docs
        .map((d) => AccessCode.fromSnapshot(d))
        .where((code) => code.usedBy.any((u) => u.studentId == studentId))
        .toList();
  }

  Future<void> deleteStudent(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ===== ATTENDANCE =====

  Stream<List<AttendanceSession>> getAttendanceSessions() {
    return _db
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AttendanceSession.fromSnapshot(d)).toList());
  }

  Future<AttendanceSession> createAttendanceSession(
      DateTime date, String title) async {
    final doc = await _db.collection('attendance').add({
      'date': Timestamp.fromDate(date),
      'title': title,
      'defaultPrice': 0.0,
      'presentStudents': [],
      'isEnded': false,
    });
    return AttendanceSession(id: doc.id, date: date, title: title);
  }

  Future<void> updateAttendanceSession(AttendanceSession session) async {
    await _db.collection('attendance').doc(session.id).update(session.toMap());
  }

  Future<void> deleteAttendanceSession(String id) async {
    await _db.collection('attendance').doc(id).delete();
  }

  // ===== ANNOUNCEMENTS =====

  Stream<List<Announcement>> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Announcement.fromSnapshot(d)).toList());
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    await _db
        .collection('announcements')
        .doc(announcement.id)
        .set(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }
}
