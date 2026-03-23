import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String grade;
  final String password;
  final String studentCode; // ← NEW
  final DateTime createdAt;
  final bool isDisabled;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.grade = '',
    this.password = '',
    this.studentCode = '', // ← NEW
    DateTime? createdAt,
    this.isDisabled = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'grade': grade,
      'password': password,
      'studentCode': studentCode, // ← NEW
      'createdAt': Timestamp.fromDate(createdAt),
      'isDisabled': isDisabled,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      grade: map['grade'] ?? '',
      password: map['password'] ?? '',
      studentCode: map['studentCode'] ?? '', // ← NEW
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDisabled: map['isDisabled'] ?? false,
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? grade,
    String? password,
    String? studentCode, // ← NEW
    bool? isDisabled,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      role: role,
      grade: grade ?? this.grade,
      password: password ?? this.password,
      studentCode: studentCode ?? this.studentCode, // ← NEW
      createdAt: createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
