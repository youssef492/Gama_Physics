import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedData() async {
    // Check if data already exists
    final stages = await _db.collection('stages').get();
    if (stages.docs.isNotEmpty) {
      throw Exception('البيانات موجودة بالفعل. احذف البيانات أولاً لإعادة التعبئة.');
    }

    // Create 2 stages
    final stage1 = await _db.collection('stages').add({
      'name': 'الصف الأول الثانوي',
      'order': 1,
    });
    final stage2 = await _db.collection('stages').add({
      'name': 'الصف الثاني الثانوي',
      'order': 2,
    });

    // Create 2 semesters per stage
    final sem1_1 = await _db.collection('semesters').add({
      'stageId': stage1.id,
      'name': 'الفصل الدراسي الأول',
      'order': 1,
    });
    final sem1_2 = await _db.collection('semesters').add({
      'stageId': stage1.id,
      'name': 'الفصل الدراسي الثاني',
      'order': 2,
    });
    final sem2_1 = await _db.collection('semesters').add({
      'stageId': stage2.id,
      'name': 'الفصل الدراسي الأول',
      'order': 1,
    });
    final sem2_2 = await _db.collection('semesters').add({
      'stageId': stage2.id,
      'name': 'الفصل الدراسي الثاني',
      'order': 2,
    });

    // Create 6 lessons (mix of free and paid)
    final lessons = [
      {
        'stageId': stage1.id,
        'semesterId': sem1_1.id,
        'title': 'مقدمة في الفيزياء',
        'description': 'درس تمهيدي عن أساسيات الفيزياء وأهميتها',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'free',
        'isVisible': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'stageId': stage1.id,
        'semesterId': sem1_1.id,
        'title': 'قوانين نيوتن للحركة',
        'description': 'شرح مفصل لقوانين نيوتن الثلاثة',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'paid',
        'isVisible': true,
        'order': 2,
        'createdAt': Timestamp.now(),
      },
      {
        'stageId': stage1.id,
        'semesterId': sem1_2.id,
        'title': 'الطاقة والشغل',
        'description': 'مفهوم الطاقة وأنواعها والعلاقة بين الشغل والطاقة',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'paid',
        'isVisible': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'stageId': stage2.id,
        'semesterId': sem2_1.id,
        'title': 'الكهرباء الساكنة',
        'description': 'الشحنات الكهربائية وقانون كولوم',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'free',
        'isVisible': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'stageId': stage2.id,
        'semesterId': sem2_1.id,
        'title': 'التيار الكهربائي',
        'description': 'دوائر التيار المستمر وقانون أوم',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'paid',
        'isVisible': true,
        'order': 2,
        'createdAt': Timestamp.now(),
      },
      {
        'stageId': stage2.id,
        'semesterId': sem2_2.id,
        'title': 'المغناطيسية',
        'description': 'المجال المغناطيسي والقوة المغناطيسية',
        'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'videoType': 'youtube',
        'lessonType': 'paid',
        'isVisible': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
    ];

    // Add lessons and collect their IDs
    List<String> paidLessonIds = [];
    for (var lesson in lessons) {
      final doc = await _db.collection('lessons').add(lesson);
      if (lesson['lessonType'] == 'paid') {
        paidLessonIds.add(doc.id);
      }
    }

    // Create 10 access codes for paid lessons
    for (int i = 0; i < 10; i++) {
      final lessonId = paidLessonIds[i % paidLessonIds.length];
      final code = _generateCode(6);
      await _db.collection('accessCodes').add({
        'code': code,
        'lessonId': lessonId,
        'maxUses': 3,
        'currentUses': 0,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30))),
        'status': 'active',
        'usedBy': [],
        'createdBy': 'seed',
        'createdAt': Timestamp.now(),
      });
    }
  }

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Create a teacher account
  Future<void> createTeacherAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'phone': '',
        'email': email,
        'role': 'teacher',
        'grade': '',
        'passwordHash': '',
        'createdAt': Timestamp.now(),
        'isDisabled': false,
      });
    } catch (e) {
      rethrow;
    }
  }
}
