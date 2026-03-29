import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'Gama Physics'**
  String get appTitle;

  /// No description provided for @studentLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول الطالب'**
  String get studentLogin;

  /// No description provided for @teacherLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول المدرس'**
  String get teacherLogin;

  /// No description provided for @iAmStudent.
  ///
  /// In ar, this message translates to:
  /// **'أنا طالب'**
  String get iAmStudent;

  /// No description provided for @iAmTeacher.
  ///
  /// In ar, this message translates to:
  /// **'أنا مدرس'**
  String get iAmTeacher;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك'**
  String get welcome;

  /// No description provided for @loginWithPhone.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك برقم الهاتف وكلمة المرور'**
  String get loginWithPhone;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In ar, this message translates to:
  /// **'سجل الآن'**
  String get registerNow;

  /// No description provided for @newStudent.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل طالب جديد'**
  String get newStudent;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @stage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الدراسية'**
  String get stage;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @createAccountBtn.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get createAccountBtn;

  /// No description provided for @haveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get haveAccount;

  /// No description provided for @teacherPanel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المدرس'**
  String get teacherPanel;

  /// No description provided for @loginToPanel.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك للوحة التحكم'**
  String get loginToPanel;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @stages.
  ///
  /// In ar, this message translates to:
  /// **'المراحل الدراسية'**
  String get stages;

  /// No description provided for @semesters.
  ///
  /// In ar, this message translates to:
  /// **'الفصول الدراسية'**
  String get semesters;

  /// No description provided for @lessons.
  ///
  /// In ar, this message translates to:
  /// **'الدروس'**
  String get lessons;

  /// No description provided for @manageLessons.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الدروس'**
  String get manageLessons;

  /// No description provided for @manageStages.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المراحل'**
  String get manageStages;

  /// No description provided for @manageCodes.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأكواد'**
  String get manageCodes;

  /// No description provided for @manageStudents.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الطلاب'**
  String get manageStudents;

  /// No description provided for @controlPanel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get controlPanel;

  /// No description provided for @welcomeTeacher.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك أستاذ'**
  String get welcomeTeacher;

  /// No description provided for @free.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get free;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paid;

  /// No description provided for @visible.
  ///
  /// In ar, this message translates to:
  /// **'ظاهر'**
  String get visible;

  /// No description provided for @hidden.
  ///
  /// In ar, this message translates to:
  /// **'مخفي'**
  String get hidden;

  /// No description provided for @noLessons.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دروس متاحة حالياً'**
  String get noLessons;

  /// No description provided for @noStages.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مراحل متاحة حالياً'**
  String get noStages;

  /// No description provided for @noSemesters.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فصول متاحة'**
  String get noSemesters;

  /// No description provided for @paidLesson.
  ///
  /// In ar, this message translates to:
  /// **'درس مدفوع'**
  String get paidLesson;

  /// No description provided for @enterCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود الوصول لمشاهدة الدرس'**
  String get enterCode;

  /// No description provided for @code.
  ///
  /// In ar, this message translates to:
  /// **'الكود'**
  String get code;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @invalidCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صالح أو منتهي الصلاحية'**
  String get invalidCode;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPassword;

  /// No description provided for @savePassword.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور'**
  String get savePassword;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @students.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get students;

  /// No description provided for @studentCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطلاب'**
  String get studentCount;

  /// No description provided for @searchStudents.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو رقم الهاتف...'**
  String get searchStudents;

  /// No description provided for @noStudents.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب'**
  String get noStudents;

  /// No description provided for @disableAccount.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل الحساب'**
  String get disableAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get deleteAccount;

  /// No description provided for @deleteAnnouncementConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا الإعلان؟'**
  String get deleteAnnouncementConfirm;

  /// No description provided for @announcements.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get announcements;

  /// No description provided for @newAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'إعلان جديد'**
  String get newAnnouncement;

  /// No description provided for @announcementTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإعلان'**
  String get announcementTitle;

  /// No description provided for @announcementContent.
  ///
  /// In ar, this message translates to:
  /// **'نص الإعلان'**
  String get announcementContent;

  /// No description provided for @noAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات حالياً'**
  String get noAnnouncements;

  /// No description provided for @announcementAdded.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة الإعلان بنجاح'**
  String get announcementAdded;

  /// No description provided for @announcementUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الإعلان بنجاح'**
  String get announcementUpdated;

  /// No description provided for @announcementDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الإعلان بنجاح'**
  String get announcementDeleted;

  /// No description provided for @editAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإعلان'**
  String get editAnnouncement;

  /// No description provided for @announcementViewers.
  ///
  /// In ar, this message translates to:
  /// **'مشاهدو الإعلان'**
  String get announcementViewers;

  /// No description provided for @noAnnouncementViewers.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مشاهدات حتى الآن'**
  String get noAnnouncementViewers;

  /// No description provided for @deleteStudentConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف حساب'**
  String get deleteStudentConfirm;

  /// No description provided for @deleteWarning.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف بيانات الطالب نهائياً.'**
  String get deleteWarning;

  /// No description provided for @deleteBtn.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get deleteBtn;

  /// No description provided for @deletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب بنجاح'**
  String get deletedSuccess;

  /// No description provided for @codes.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد'**
  String get codes;

  /// No description provided for @generateCodes.
  ///
  /// In ar, this message translates to:
  /// **'توليد أكواد'**
  String get generateCodes;

  /// No description provided for @noCodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد. أنشئ أكواد جديدة.'**
  String get noCodes;

  /// No description provided for @codesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأكواد'**
  String get codesCount;

  /// No description provided for @maxUses.
  ///
  /// In ar, this message translates to:
  /// **'عدد مرات الاستخدام لكل كود'**
  String get maxUses;

  /// No description provided for @validity.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية (بالأيام)'**
  String get validity;

  /// No description provided for @generate.
  ///
  /// In ar, this message translates to:
  /// **'توليد'**
  String get generate;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'فعال'**
  String get active;

  /// No description provided for @used.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get used;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @disabled.
  ///
  /// In ar, this message translates to:
  /// **'معطل'**
  String get disabled;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get disable;

  /// No description provided for @usedCodes.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد المستخدمة'**
  String get usedCodes;

  /// No description provided for @noUsedCodes.
  ///
  /// In ar, this message translates to:
  /// **'لم يستخدم أي أكواد'**
  String get noUsedCodes;

  /// No description provided for @registrationDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التسجيل'**
  String get registrationDate;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @notSaved.
  ///
  /// In ar, this message translates to:
  /// **'غير محفوظة'**
  String get notSaved;

  /// No description provided for @usage.
  ///
  /// In ar, this message translates to:
  /// **'الاستخدام'**
  String get usage;

  /// No description provided for @expiresOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي'**
  String get expiresOn;

  /// No description provided for @usedBy.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get usedBy;

  /// No description provided for @addStage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مرحلة'**
  String get addStage;

  /// No description provided for @editStage.
  ///
  /// In ar, this message translates to:
  /// **'تعديل مرحلة'**
  String get editStage;

  /// No description provided for @stageName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المرحلة'**
  String get stageName;

  /// No description provided for @order.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get order;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @deleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get deleteConfirm;

  /// No description provided for @deleteStageConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف'**
  String get deleteStageConfirm;

  /// No description provided for @addSemester.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فصل'**
  String get addSemester;

  /// No description provided for @editSemester.
  ///
  /// In ar, this message translates to:
  /// **'تعديل فصل'**
  String get editSemester;

  /// No description provided for @semesterName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الفصل'**
  String get semesterName;

  /// No description provided for @addLesson.
  ///
  /// In ar, this message translates to:
  /// **'إضافة درس'**
  String get addLesson;

  /// No description provided for @editLesson.
  ///
  /// In ar, this message translates to:
  /// **'تعديل درس'**
  String get editLesson;

  /// No description provided for @lessonTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدرس'**
  String get lessonTitle;

  /// No description provided for @lessonDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف الدرس'**
  String get lessonDescription;

  /// No description provided for @videoUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط الفيديو'**
  String get videoUrl;

  /// No description provided for @videoType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الفيديو'**
  String get videoType;

  /// No description provided for @lessonType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الدرس'**
  String get lessonType;

  /// No description provided for @visibleToStudents.
  ///
  /// In ar, this message translates to:
  /// **'ظاهر للطلاب'**
  String get visibleToStudents;

  /// No description provided for @youtubeHint.
  ///
  /// In ar, this message translates to:
  /// **'للتشغيل داخل التطبيق: من YouTube Studio ← تعديل الفيديو ← تفعيل «السماح بالتضمين».'**
  String get youtubeHint;

  /// No description provided for @lessonDescription2.
  ///
  /// In ar, this message translates to:
  /// **'وصف الدرس'**
  String get lessonDescription2;

  /// No description provided for @testData.
  ///
  /// In ar, this message translates to:
  /// **'تعبئة بيانات تجريبية'**
  String get testData;

  /// No description provided for @dataExists.
  ///
  /// In ar, this message translates to:
  /// **'البيانات موجودة بالفعل.'**
  String get dataExists;

  /// No description provided for @testDataSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة البيانات التجريبية بنجاح'**
  String get testDataSuccess;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @loadingLessons.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الدروس...'**
  String get loadingLessons;

  /// No description provided for @failedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الدروس'**
  String get failedToLoad;

  /// No description provided for @physicsDesc.
  ///
  /// In ar, this message translates to:
  /// **'منصة تعليم الفيزياء'**
  String get physicsDesc;

  /// No description provided for @copyright.
  ///
  /// In ar, this message translates to:
  /// **'© 2026 Gama Physics'**
  String get copyright;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير متطابقة'**
  String get passwordMismatch;

  /// No description provided for @enterPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الهاتف وكلمة المرور'**
  String get enterPhone;

  /// No description provided for @enterEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد الإلكتروني وكلمة المرور'**
  String get enterEmail;

  /// No description provided for @enterName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get enterName;

  /// No description provided for @phoneAlreadyUsed.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف مسجل بالفعل'**
  String get phoneAlreadyUsed;

  /// No description provided for @wrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة'**
  String get wrongPassword;

  /// No description provided for @userNotFound.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير مسجل'**
  String get userNotFound;

  /// No description provided for @unexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get unexpectedError;

  /// No description provided for @accountDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تعطيل حسابك. تواصل مع المدرس.'**
  String get accountDisabled;

  /// No description provided for @notTeacherAccount.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب ليس حساب مدرس'**
  String get notTeacherAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح'**
  String get invalidEmail;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح'**
  String get passwordChangeSuccess;

  /// No description provided for @passwordChangeError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تغيير كلمة المرور'**
  String get passwordChangeError;

  /// No description provided for @generatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد {count} كود بنجاح'**
  String generatedSuccess(int count);

  /// No description provided for @welcomeStudent.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً {name} 👋'**
  String welcomeStudent(String name);

  /// No description provided for @editExpiryTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تاريخ الانتهاء'**
  String get editExpiryTooltip;

  /// No description provided for @editExpiryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تاريخ انتهاء الأكواد'**
  String get editExpiryTitle;

  /// No description provided for @editExpirySingleTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تاريخ الانتهاء'**
  String get editExpirySingleTitle;

  /// No description provided for @bulkExpirySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار درس وحدد تاريخ انتهاء جديد لكل أكواده'**
  String get bulkExpirySubtitle;

  /// No description provided for @noPaidLessons.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دروس مدفوعة'**
  String get noPaidLessons;

  /// No description provided for @lessonDropdownLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدرس'**
  String get lessonDropdownLabel;

  /// No description provided for @pickExpiryDate.
  ///
  /// In ar, this message translates to:
  /// **'اختار تاريخ الانتهاء'**
  String get pickExpiryDate;

  /// No description provided for @pickNewDate.
  ///
  /// In ar, this message translates to:
  /// **'اختار تاريخ جديد'**
  String get pickNewDate;

  /// No description provided for @pastDateWarningBulk.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ في الماضي — الأكواد ستُعلَّم منتهية'**
  String get pastDateWarningBulk;

  /// No description provided for @pastDateWarningSingle.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ في الماضي — الكود سيُعلَّم منتهياً'**
  String get pastDateWarningSingle;

  /// No description provided for @update.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get update;

  /// No description provided for @expiryRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تم إزالة تاريخ الانتهاء'**
  String get expiryRemoved;

  /// No description provided for @bulkUpdateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث {count} كود — {date}'**
  String bulkUpdateSuccess(int count, String date);

  /// No description provided for @singleUpdateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التحديث: {date}'**
  String singleUpdateSuccess(String date);

  /// No description provided for @changeGrade.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المرحلة الدراسية'**
  String get changeGrade;

  /// No description provided for @gradeUpdateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المرحلة الدراسية بنجاح'**
  String get gradeUpdateSuccess;

  /// No description provided for @gradeAlreadyCurrent.
  ///
  /// In ar, this message translates to:
  /// **'هذه هي مرحلتك الحالية'**
  String get gradeAlreadyCurrent;

  /// No description provided for @playbackSpeed.
  ///
  /// In ar, this message translates to:
  /// **'سرعة التشغيل'**
  String get playbackSpeed;

  /// No description provided for @videoQuality.
  ///
  /// In ar, this message translates to:
  /// **'جودة الفيديو'**
  String get videoQuality;

  /// No description provided for @skipForward10.
  ///
  /// In ar, this message translates to:
  /// **'+10 ثانية'**
  String get skipForward10;

  /// No description provided for @skipBackward10.
  ///
  /// In ar, this message translates to:
  /// **'-10 ثانية'**
  String get skipBackward10;

  /// No description provided for @attendance.
  ///
  /// In ar, this message translates to:
  /// **'الغياب'**
  String get attendance;

  /// No description provided for @takeAttendance.
  ///
  /// In ar, this message translates to:
  /// **'أخذ الغياب'**
  String get takeAttendance;

  /// No description provided for @newSession.
  ///
  /// In ar, this message translates to:
  /// **'حصة جديدة'**
  String get newSession;

  /// No description provided for @scanQrCode.
  ///
  /// In ar, this message translates to:
  /// **'مسح كود QR او Barcode'**
  String get scanQrCode;

  /// No description provided for @searchStudent.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن طالب بالاسم أو الرقم...'**
  String get searchStudent;

  /// No description provided for @markPresent.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور'**
  String get markPresent;

  /// No description provided for @presentStudents.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب الحاضرون'**
  String get presentStudents;

  /// No description provided for @removeFromSession.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من الحصة'**
  String get removeFromSession;

  /// No description provided for @sessionDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الحصة'**
  String get sessionDate;

  /// No description provided for @sessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الحصة (اختياري)'**
  String get sessionTitle;

  /// No description provided for @endSession.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الحصة'**
  String get endSession;

  /// No description provided for @sessionPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الحصة للطالب'**
  String get sessionPrice;

  /// No description provided for @studentPayment.
  ///
  /// In ar, this message translates to:
  /// **'دفع الطالب'**
  String get studentPayment;

  /// No description provided for @generatePdf.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء PDF'**
  String get generatePdf;

  /// No description provided for @paidAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get paidAmount;

  /// No description provided for @notPaid.
  ///
  /// In ar, this message translates to:
  /// **'لم يدفع'**
  String get notPaid;

  /// No description provided for @savePdf.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومشاركة PDF'**
  String get savePdf;

  /// No description provided for @confirmEndSession.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إنهاء الحصة؟'**
  String get confirmEndSession;

  /// No description provided for @sessionEndedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء الحصة بنجاح!'**
  String get sessionEndedSuccess;

  /// No description provided for @videoNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو غير متاح'**
  String get videoNotAvailable;

  /// No description provided for @videoNotAvailableDesc.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو غير متاح حالياً. يرجى المحاولة مرة أخرى لاحقاً.'**
  String get videoNotAvailableDesc;

  /// No description provided for @video_loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الفيديو...'**
  String get video_loading;

  /// No description provided for @video_error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل الفيديو'**
  String get video_error;

  /// No description provided for @video_retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get video_retry;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @lessonNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الدرس غير موجود'**
  String get lessonNotFound;

  /// No description provided for @lessonViewers.
  ///
  /// In ar, this message translates to:
  /// **'مشاهدو الدرس'**
  String get lessonViewers;

  /// No description provided for @failedToLoadData.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل البيانات'**
  String get failedToLoadData;

  /// No description provided for @noLessonViewers.
  ///
  /// In ar, this message translates to:
  /// **'لم يشاهد أحد هذا الدرس بعد'**
  String get noLessonViewers;

  /// No description provided for @studentWatched.
  ///
  /// In ar, this message translates to:
  /// **'طالب شاهد'**
  String get studentWatched;

  /// No description provided for @totalViews.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشاهدات'**
  String get totalViews;

  /// No description provided for @firstWatch.
  ///
  /// In ar, this message translates to:
  /// **'أول مشاهدة'**
  String get firstWatch;

  /// No description provided for @lastWatch.
  ///
  /// In ar, this message translates to:
  /// **'آخر مشاهدة'**
  String get lastWatch;

  /// No description provided for @preparingVideo.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز الفيديو'**
  String get preparingVideo;

  /// No description provided for @slowNetwork.
  ///
  /// In ar, this message translates to:
  /// **'الشبكة بطيئة'**
  String get slowNetwork;

  /// No description provided for @slowNetworkDesc.
  ///
  /// In ar, this message translates to:
  /// **'النت بطيء شوية، حاول تاني أو انتظر'**
  String get slowNetworkDesc;

  /// No description provided for @noInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get noInternet;

  /// No description provided for @noInternetDesc.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الاتصال وحاول مرة أخرى'**
  String get noInternetDesc;

  /// No description provided for @cannotPlayVideo.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل الفيديو'**
  String get cannotPlayVideo;

  /// No description provided for @cannotPlayVideoDesc.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get cannotPlayVideoDesc;

  /// No description provided for @extractingLink.
  ///
  /// In ar, this message translates to:
  /// **'جاري استخراج الرابط...'**
  String get extractingLink;

  /// No description provided for @preparingPlayback.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحضير للتشغيل...'**
  String get preparingPlayback;

  /// No description provided for @almostReady.
  ///
  /// In ar, this message translates to:
  /// **'تقريبًا جاهز...'**
  String get almostReady;

  /// No description provided for @exportExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير Excel'**
  String get exportExcel;

  /// No description provided for @exportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير: {error}'**
  String exportFailed(String error);

  /// No description provided for @present.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get present;

  /// No description provided for @studentNotFound.
  ///
  /// In ar, this message translates to:
  /// **'طالب غير موجود'**
  String get studentNotFound;

  /// No description provided for @searchAndAddStudent.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن طالب وأضفه'**
  String get searchAndAddStudent;

  /// No description provided for @exportSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التصدير بنجاح!'**
  String get exportSuccess;

  /// No description provided for @fileSavedInDownloads.
  ///
  /// In ar, this message translates to:
  /// **'الملف محفوظ في Downloads\nافتحه من تطبيق Files'**
  String get fileSavedInDownloads;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get ok;

  /// No description provided for @timesWatched.
  ///
  /// In ar, this message translates to:
  /// **'{count}× شاهد'**
  String timesWatched(int count);

  /// No description provided for @qrCode.
  ///
  /// In ar, this message translates to:
  /// **'كود QR'**
  String get qrCode;

  /// No description provided for @studentCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود الطالب'**
  String get studentCodeLabel;

  /// No description provided for @generatingCode.
  ///
  /// In ar, this message translates to:
  /// **'جاري إنشاء الكود...'**
  String get generatingCode;

  /// No description provided for @noCodeYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد كود بعد'**
  String get noCodeYet;

  /// No description provided for @view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get view;

  /// No description provided for @errorLoadingSessions.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل الحصص'**
  String get errorLoadingSessions;

  /// No description provided for @noSessionsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حصص بعد'**
  String get noSessionsYet;

  /// No description provided for @youtube.
  ///
  /// In ar, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @googleDrive.
  ///
  /// In ar, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @newLabel.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newLabel;

  /// No description provided for @exportPdf.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPdf;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @fullScreen.
  ///
  /// In ar, this message translates to:
  /// **'عرض كامل'**
  String get fullScreen;

  /// No description provided for @addPdfLinks.
  ///
  /// In ar, this message translates to:
  /// **'إضافة روابط ملفات PDF'**
  String get addPdfLinks;

  /// No description provided for @pdfLinks.
  ///
  /// In ar, this message translates to:
  /// **'ملفات PDF للدرس'**
  String get pdfLinks;

  /// No description provided for @pdfUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط ملف PDF'**
  String get pdfUrl;

  /// No description provided for @addPdf.
  ///
  /// In ar, this message translates to:
  /// **'إضافة PDF'**
  String get addPdf;

  /// No description provided for @removePdf.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get removePdf;

  /// No description provided for @noPdfs.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات PDF'**
  String get noPdfs;

  /// No description provided for @downloadPdf.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الملف'**
  String get downloadPdf;

  /// No description provided for @viewPdf.
  ///
  /// In ar, this message translates to:
  /// **'عرض ملف PDF'**
  String get viewPdf;

  /// No description provided for @invalidPdfUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط PDF غير صحيح'**
  String get invalidPdfUrl;

  /// No description provided for @pdfPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة PDF'**
  String get pdfPreview;

  /// No description provided for @openPdfInBrowser.
  ///
  /// In ar, this message translates to:
  /// **'فتح PDF في المتصفح'**
  String get openPdfInBrowser;

  /// No description provided for @pdfDesktopHint.
  ///
  /// In ar, this message translates to:
  /// **'على ويندوز ولينكس يُفتح ملف PDF في المتصفح الافتراضي (لا يتوفر عارض مدمج).'**
  String get pdfDesktopHint;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'عودة'**
  String get back;

  /// No description provided for @pdfLinkOptional.
  ///
  /// In ar, this message translates to:
  /// **'رابط PDF (اختياري)'**
  String get pdfLinkOptional;

  /// No description provided for @invalidUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط غير صالح'**
  String get invalidUrl;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
