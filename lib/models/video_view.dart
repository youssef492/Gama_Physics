import 'package:cloud_firestore/cloud_firestore.dart';

class VideoView {
  final String lessonId;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentGrade;
  final DateTime firstWatchedAt;
  final DateTime lastWatchedAt;
  final int watchCount;

  VideoView({
    required this.lessonId,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentGrade,
    required this.firstWatchedAt,
    required this.lastWatchedAt,
    this.watchCount = 1,
  });

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'studentId': studentId,
        'studentName': studentName,
        'studentPhone': studentPhone,
        'studentGrade': studentGrade,
        'firstWatchedAt': Timestamp.fromDate(firstWatchedAt),
        'lastWatchedAt': Timestamp.fromDate(lastWatchedAt),
        'watchCount': watchCount,
      };

  factory VideoView.fromMap(Map<String, dynamic> map) => VideoView(
        lessonId: map['lessonId'] ?? '',
        studentId: map['studentId'] ?? '',
        studentName: map['studentName'] ?? '',
        studentPhone: map['studentPhone'] ?? '',
        studentGrade: map['studentGrade'] ?? '',
        firstWatchedAt:
            (map['firstWatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastWatchedAt:
            (map['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        watchCount: map['watchCount'] ?? 1,
      );

  factory VideoView.fromSnapshot(DocumentSnapshot doc) =>
      VideoView.fromMap(doc.data() as Map<String, dynamic>);
}
