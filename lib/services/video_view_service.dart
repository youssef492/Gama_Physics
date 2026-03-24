import 'package:async/async.dart';
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

      // ✅ نستخدم update وبعدها set لو مفيش دوكيومنت (عشان نتجنب مشكلة الـ get في الـ Rules لدوكيومنت مش موجود)
      try {
        await docRef.update({
          'lastWatchedAt': now,
          'watchCount': FieldValue.increment(1),
          // نحدّث البيانات الشخصية (لو اتغيرت)
          'studentName': studentName,
          'studentPhone': studentPhone,
          'studentGrade': studentGrade,
        });
      } catch (e) {
        // لو الـ Document مش موجود، الـ update هيعمل throw، هنا هنعمل set بدل ما نقرأ الأول
        await docRef.set({
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

  static Future<int> getTotalViewsCount(String lessonId) async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('lessonId', isEqualTo: lessonId)
          .get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('[VideoViewService] getTotalViewsCount error: $e');
      return 0;
    }
  }

  static Stream<Map<String, int>> getViewCountsStream(List<String> lessonIds) {
    if (lessonIds.isEmpty) return Stream.value({});

    final chunks = <List<String>>[];
    for (var i = 0; i < lessonIds.length; i += 10) {
      chunks.add(lessonIds.sublist(i, (i + 10).clamp(0, lessonIds.length)));
    }

    if (chunks.length == 1) {
      return _db
          .collection(_collection)
          .where('lessonId', whereIn: chunks.first)
          .snapshots()
          .map((snap) {
        final counts = <String, int>{for (final id in lessonIds) id: 0};
        for (final doc in snap.docs) {
          final lid = doc.data()['lessonId'] as String;
          counts[lid] = (counts[lid] ?? 0) + 1;
        }
        return counts;
      });
    }

    // أكتر من 10 دروس: ادمج streams
    return StreamZip(
      chunks.map((chunk) => _db
              .collection(_collection)
              .where('lessonId', whereIn: chunk)
              .snapshots()
              .map((snap) {
            final counts = <String, int>{};
            for (final doc in snap.docs) {
              final lid = doc.data()['lessonId'] as String;
              counts[lid] = (counts[lid] ?? 0) + 1;
            }
            return counts;
          })),
    ).map((maps) {
      final merged = <String, int>{for (final id in lessonIds) id: 0};
      for (final m in maps) {
        m.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
      }
      return merged;
    });
  }
}
