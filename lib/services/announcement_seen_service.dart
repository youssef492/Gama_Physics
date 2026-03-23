import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementSeenService {
  static const _key = 'last_seen_announcement_ms';

  /// يحفظ الوقت الحالي كـ "آخر مرة شاف الإعلانات"
  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
  }

  /// يرجع الـ timestamp اللي آخر مرة فتح فيه الطالب الإعلانات
  /// لو مفيش سجل → يرجع null (يعني لم يفتحها قبل كده)
  static Future<DateTime?> getLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// هل في إعلانات جديدة من بعد آخر زيارة؟
  /// بياخد أحدث تاريخ إعلان وبيقارنه بالـ lastSeen
  static Future<bool> hasUnseenAnnouncements(
      List<DateTime> announcementDates) async {
    if (announcementDates.isEmpty) return false;
    final lastSeen = await getLastSeen();
    if (lastSeen == null) return true; // لو ما فتحش قبل كده → في جديد
    final latest = announcementDates.reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isAfter(lastSeen);
  }
}
