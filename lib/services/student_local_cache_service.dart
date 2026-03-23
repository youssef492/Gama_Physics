import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class StudentLocalCacheService {
  static const String _cacheKey = 'cached_student_profile_v1';

  static Map<String, dynamic> _toCacheMap(AppUser user) {
    return {
      'uid': user.uid,
      'name': user.name,
      'phone': user.phone,
      'email': user.email,
      'role': user.role,
      'grade': user.grade,
      // QR code is generated from uid, and the "studentCode" is shown in the UI.
      'studentCode': user.studentCode,
      'createdAtMs': user.createdAt.millisecondsSinceEpoch,
      'isDisabled': user.isDisabled,
    };
  }

  static AppUser _fromCacheMap(Map<String, dynamic> map) {
    final createdAtMs = map['createdAtMs'] as int?;
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      grade: map['grade'] ?? '',
      password: '',
      studentCode: map['studentCode'] ?? '',
      createdAt: createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
      isDisabled: map['isDisabled'] ?? false,
    );
  }

  static Future<void> saveStudent(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_toCacheMap(user)));
  }

  static Future<AppUser?> loadStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _fromCacheMap(map);
    } catch (_) {
      return null;
    }
  }
}

