import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/video_view.dart';

class VideoViewService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'videoViews';

  static String _docId(String lessonId, String studentId) =>
      '${lessonId}_$studentId';

  /// يسجّل مشاهدة الطالب للدرس
  /// ✅ تحسين: استخدام set+merge بدون الحاجة لـ update منفصل
  static Future<void> recordView({
    required String lessonId,
    required String studentId,
    required String studentName,
    required String studentPhone,
    required String studentGrade,
  }) async {
    if (lessonId.isEmpty || studentId.isEmpty) return;

    try {
      final docRef =
          _db.collection(_collection).doc(_docId(lessonId, studentId));
      final now = Timestamp.fromDate(DateTime.now());

      // ✅ نستخدم transaction عشان نتأكد من firstWatchedAt
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          // Document موجود → نحدّث watchCount و lastWatchedAt بس
          transaction.update(docRef, {
            'lastWatchedAt': now,
            'watchCount': FieldValue.increment(1),
            // نحدّث البيانات الشخصية (لو اتغيرت)
            'studentName': studentName,
            'studentPhone': studentPhone,
            'studentGrade': studentGrade,
          });
        } else {
          // Document جديد → نضيف firstWatchedAt كمان
          transaction.set(docRef, {
            'lessonId': lessonId,
            'studentId': studentId,
            'studentName': studentName,
            'studentPhone': studentPhone,
            'studentGrade': studentGrade,
            'firstWatchedAt': now,
            'lastWatchedAt': now,
            'watchCount': 1,
          });
        }
      });
    } catch (e) {
      debugPrint('[VideoViewService] recordView error: $e');
    }
  }

  static Stream<List<VideoView>> getViewsForLesson(String lessonId) {
    return _db
        .collection(_collection)
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) {
      final views = snap.docs.map((d) => VideoView.fromSnapshot(d)).toList();
      views.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
      return views;
    });
  }

  static Future<int> getUniqueViewersCount(String lessonId) async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('lessonId', isEqualTo: lessonId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[VideoViewService] getUniqueViewersCount error: $e');
      return 0;
    }
  }
}
