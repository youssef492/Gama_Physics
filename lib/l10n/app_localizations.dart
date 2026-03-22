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
