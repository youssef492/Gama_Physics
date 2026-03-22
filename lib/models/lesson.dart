import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String stageId;
  final String semesterId;
  final String title;
  final String description;
  final String videoUrl;
  final String videoType; // 'youtube' or 'drive'
  final String lessonType; // 'free' or 'paid'
  final bool isVisible;
  final int order;
  final DateTime createdAt;

  Lesson({
    required this.id,
    required this.stageId,
    required this.semesterId,
    required this.title,
    this.description = '',
    required this.videoUrl,
    required this.videoType,
    required this.lessonType,
    this.isVisible = true,
    required this.order,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFree => lessonType == 'free';
  bool get isPaid => lessonType == 'paid';

  String get embedUrl {
    if (videoType == 'youtube') {
      // Extract video ID from various YouTube URL formats
      final uri = Uri.tryParse(videoUrl);
      String? videoId;
      if (uri != null) {
        if (uri.host.contains('youtu.be')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        } else if (uri.host.contains('youtube.com')) {
          videoId = uri.queryParameters['v'];
          if (videoId == null && uri.pathSegments.contains('embed')) {
            final idx = uri.pathSegments.indexOf('embed');
            if (idx + 1 < uri.pathSegments.length) {
              videoId = uri.pathSegments[idx + 1];
            }
          }
        }
      }
      if (videoId != null) {
        return 'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&showinfo=0';
      }
      return videoUrl;
    } else if (videoType == 'drive') {
      // Extract file ID from Google Drive URL
      final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(videoUrl);
      if (match != null) {
        return 'https://drive.google.com/file/d/${match.group(1)}/preview';
      }
      return videoUrl;
    }
    return videoUrl;
  }

  Map<String, dynamic> toMap() {
    return {
      'stageId': stageId,
      'semesterId': semesterId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'videoType': videoType,
      'lessonType': lessonType,
      'isVisible': isVisible,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Lesson.fromMap(String id, Map<String, dynamic> map) {
    return Lesson(
      id: id,
      stageId: map['stageId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      videoType: map['videoType'] ?? 'youtube',
      lessonType: map['lessonType'] ?? 'free',
      isVisible: map['isVisible'] ?? true,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Lesson.fromSnapshot(DocumentSnapshot doc) {
    return Lesson.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Lesson copyWith({
    String? title,
    String? description,
    String? videoUrl,
    String? videoType,
    String? lessonType,
    bool? isVisible,
    int? order,
  }) {
    return Lesson(
      id: id,
      stageId: stageId,
      semesterId: semesterId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      videoType: videoType ?? this.videoType,
      lessonType: lessonType ?? this.lessonType,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
