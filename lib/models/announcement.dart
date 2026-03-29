import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String? pdfUrl;
  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorName = '',
    this.pdfUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorName': authorName,
      'pdfUrl': pdfUrl,
    };
  }

  factory Announcement.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return Announcement(
      id: snap.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorName: data['authorName'] ?? '',
      pdfUrl: data['pdfUrl'],
    );
  }
}
