import 'package:cloud_firestore/cloud_firestore.dart';

class Semester {
  final String id;
  final String stageId;
  final String name;
  final int order;

  Semester({
    required this.id,
    required this.stageId,
    required this.name,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'stageId': stageId,
      'name': name,
      'order': order,
    };
  }

  factory Semester.fromMap(String id, Map<String, dynamic> map) {
    return Semester(
      id: id,
      stageId: map['stageId'] ?? '',
      name: map['name'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  factory Semester.fromSnapshot(DocumentSnapshot doc) {
    return Semester.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
