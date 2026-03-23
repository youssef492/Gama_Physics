import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Convert phone to a fake email for Firebase Auth
  String _phoneToEmail(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    return '$phone@gama-student.app';
  }

  /// Generates a unique student code like GM-AB3X7Z
  String _generateStudentCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'GM-$code';
  }

  // ===== STUDENT AUTH =====

  Future<AppUser> registerStudent({
    required String name,
    required String phone,
    required String password,
    required String grade,
  }) async {
    final email = _phoneToEmail(phone);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = AppUser(
      uid: credential.user!.uid,
      name: name,
      phone: phone,
      email: email,
      role: 'student',
      grade: grade,
      password: password,
      studentCode: _generateStudentCode(), // ← NEW
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toMap());
    return user;
  }

  Future<UserCredential> signInStudent({
    required String phone,
    required String password,
  }) async {
    final email = _phoneToEmail(phone);
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> changeStudentPassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // ===== TEACHER AUTH =====

  Future<UserCredential> signInTeacher({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AppUser?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> saveStudentCode(String uid, String code) async {
    await _firestore.collection('users').doc(uid).update({'studentCode': code});
  }

  Future<void> updateUserGrade(String uid, String newGrade) async {
    await _firestore.collection('users').doc(uid).update({'grade': newGrade});
  }
}
