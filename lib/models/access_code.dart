import 'package:cloud_firestore/cloud_firestore.dart';

class AccessCode {
  final String id;
  final String code;
  final String lessonId;
  final int maxUses;
  final int currentUses;
  final DateTime? expiresAt;
  final String status; // 'active', 'used', 'expired', 'disabled'
  final List<CodeUsage> usedBy;
  final String createdBy; // teacher uid
  final DateTime createdAt;

  AccessCode({
    required this.id,
    required this.code,
    required this.lessonId,
    required this.maxUses,
    this.currentUses = 0,
    this.expiresAt,
    this.status = 'active',
    this.usedBy = const [],
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'active';
  bool get isExpired {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return true;
    return status == 'expired';
  }
  bool get isFullyUsed => currentUses >= maxUses;
  bool get canBeUsed => isActive && !isExpired && !isFullyUsed;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'lessonId': lessonId,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status,
      'usedBy': usedBy.map((u) => u.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AccessCode.fromMap(String id, Map<String, dynamic> map) {
    return AccessCode(
      id: id,
      code: map['code'] ?? '',
      lessonId: map['lessonId'] ?? '',
      maxUses: map['maxUses'] ?? 1,
      currentUses: map['currentUses'] ?? 0,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
      usedBy: (map['usedBy'] as List<dynamic>?)
              ?.map((u) => CodeUsage.fromMap(u as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AccessCode.fromSnapshot(DocumentSnapshot doc) {
    return AccessCode.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}

class CodeUsage {
  final String studentId;
  final String studentName;
  final DateTime usedAt;

  CodeUsage({
    required this.studentId,
    required this.studentName,
    required this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'usedAt': Timestamp.fromDate(usedAt),
    };
  }

  factory CodeUsage.fromMap(Map<String, dynamic> map) {
    return CodeUsage(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      usedAt: (map['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
