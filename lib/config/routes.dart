import 'package:flutter/material.dart';

import '../screens/auth/student_login_screen.dart';
import '../screens/auth/student_register_screen.dart';
import '../screens/auth/teacher_login_screen.dart';

// Student screens
import '../screens/student/student_home_screen.dart';
import '../screens/student/semesters_screen.dart';
import '../screens/student/lessons_screen.dart';
import '../screens/student/lesson_detail_screen.dart';
import '../screens/student/student_profile_screen.dart';
import '../screens/student/student_announcements_screen.dart';

// Teacher screens
import '../screens/teacher/teacher_dashboard_screen.dart';
import '../screens/teacher/manage_stages_screen.dart';
import '../screens/teacher/manage_semesters_screen.dart';
import '../screens/teacher/manage_lessons_screen.dart';
import '../screens/teacher/manage_codes_screen.dart';
import '../screens/teacher/student_list_screen.dart';
import '../screens/teacher/attendance_sessions_screen.dart';
import '../screens/teacher/take_attendance_screen.dart';
import '../screens/teacher/manage_announcements_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        // Auth
        '/student-login': (context) => const StudentLoginScreen(),
        '/student-register': (context) => const StudentRegisterScreen(),
        '/teacher-login': (context) => const TeacherLoginScreen(),

        // Student
        '/student-home': (context) => const StudentHomeScreen(),
        '/student-semesters': (context) => const SemestersScreen(),
        '/student-lessons': (context) => const LessonsScreen(),
        '/student-lesson-detail': (context) => const LessonDetailScreen(),
        '/student-profile': (context) => const StudentProfileScreen(),
        '/student-announcements': (context) => const StudentAnnouncementsScreen(),

        // Teacher
        '/teacher-dashboard': (context) => const TeacherDashboardScreen(),
        '/teacher-stages': (context) => const ManageStagesScreen(),
        '/teacher-semesters': (context) => const ManageSemestersScreen(),
        '/teacher-lessons': (context) => const ManageLessonsScreen(),
        '/teacher-codes': (context) => const ManageCodesScreen(),
        '/teacher-students': (context) => const StudentListScreen(),
        '/teacher-attendance': (context) => const AttendanceSessionsScreen(),
        '/take-attendance': (context) => const TakeAttendanceScreen(),
        '/teacher-announcements': (context) => const ManageAnnouncementsScreen(),
      };
}
