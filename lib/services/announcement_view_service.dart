import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/announcement_view.dart';

class AnnouncementViewService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'announcementViews';

  static String _docId(String announcementId, String studentId) =>
      '${announcementId}_$studentId';

  /// يسجل مشاهدة الطالب للإعلان
  static Future<void> recordView({
    required String announcementId,
    required String studentId,
    required String studentName,
    required String studentPhone,
    required String studentGrade,
  }) async {
    if (announcementId.isEmpty || studentId.isEmpty) return;

    try {
      final docRef = _db.collection(_collection).doc(_docId(announcementId, studentId));
      final now = Timestamp.fromDate(DateTime.now());

      // نستخدم update الأول لو موجود نحدث البيانات
      try {
        await docRef.update({
          'viewedAt': now,
          'studentName': studentName,
          'studentPhone': studentPhone,
          'studentGrade': studentGrade,
        });
      } catch (e) {
        // لو مش موجود نعمل set
        await docRef.set({
          'announcementId': announcementId,
          'studentId': studentId,
          'studentName': studentName,
          'studentPhone': studentPhone,
          'studentGrade': studentGrade,
          'viewedAt': now,
        });
      }
    } catch (e) {
      debugPrint('[AnnouncementViewService] recordView error: $e');
    }
  }

  /// يرجع قائمة باالطلام اللي شافوا الإعلان
  static Stream<List<AnnouncementView>> getViewsForAnnouncement(String announcementId) {
    return _db
        .collection(_collection)
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .map((snap) {
      final views = snap.docs.map((d) => AnnouncementView.fromSnapshot(d)).toList();
      views.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      return views;
    });
  }
}
