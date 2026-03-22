import 'package:cloud_firestore/cloud_firestore.dart';

class Stage {
  final String id;
  final String name;
  final int order;

  Stage({
    required this.id,
    required this.name,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
    };
  }

  factory Stage.fromMap(String id, Map<String, dynamic> map) {
    return Stage(
      id: id,
      name: map['name'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  factory Stage.fromSnapshot(DocumentSnapshot doc) {
    return Stage.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
