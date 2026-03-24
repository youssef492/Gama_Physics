import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementView {
  final String announcementId;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentGrade;
  final DateTime viewedAt;

  AnnouncementView({
    required this.announcementId,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentGrade,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'studentGrade': studentGrade,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }

  factory AnnouncementView.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return AnnouncementView(
      announcementId: data['announcementId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentPhone: data['studentPhone'] ?? '',
      studentGrade: data['studentGrade'] ?? '',
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
