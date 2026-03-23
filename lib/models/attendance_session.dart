import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSession {
  final String id;
  final DateTime date;
  final String title;
  final double defaultPrice;
  final List<Map<String, dynamic>> presentStudents;
  final bool isEnded;

  AttendanceSession({
    required this.id,
    required this.date,
    this.title = '',
    this.defaultPrice = 0.0,
    List<Map<String, dynamic>>? presentStudents,
    this.isEnded = false,
  }) : presentStudents = presentStudents ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'title': title,
      'defaultPrice': defaultPrice,
      'presentStudents': presentStudents,
      'isEnded': isEnded,
    };
  }

  factory AttendanceSession.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return AttendanceSession(
      id: snap.id,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      defaultPrice: (data['defaultPrice'] ?? 0.0).toDouble(),
      presentStudents: List<Map<String, dynamic>>.from(data['presentStudents'] ?? []),
      isEnded: data['isEnded'] ?? false,
    );
  }

  AttendanceSession copyWith({
    String? title,
    double? defaultPrice,
    List<Map<String, dynamic>>? presentStudents,
    bool? isEnded,
  }) {
    return AttendanceSession(
      id: id,
      date: date,
      title: title ?? this.title,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      presentStudents: presentStudents ?? this.presentStudents,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}
