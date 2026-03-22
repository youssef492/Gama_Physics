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
    // Normalize phone: remove spaces, dashes
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    return '$phone@gama-student.app';
  }

  // ===== STUDENT AUTH =====

  // Register student with phone + password (no OTP)
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
      password: password, // ← احفظه plain text علشان المدرس يشوفه
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toMap());
    return user;
  }

  // Login student with phone + password (no OTP)
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

  // Change student password
  Future<void> changeStudentPassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // Reset student password (teacher can do this)
  Future<void> resetStudentPasswordByPhone(
      String phone, String newPassword) async {
    // This would require admin SDK - for now teacher can disable/enable account
    // In free tier, student must remember password or create new account
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

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserGrade(String uid, String newGrade) async {
    await _firestore.collection('users').doc(uid).update({'grade': newGrade});
  }
}
