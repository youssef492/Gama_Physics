import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String grade;
  final String password; // ← بدل passwordHash
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
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDisabled: map['isDisabled'] ?? false,
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? grade,
    String? password,
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
      createdAt: createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
