import 'app_language.dart';

/// Bilingual UI labels for screens not tied to database content (med names still use DB fields).
abstract final class AppStrings {
  static String _t(String en, String ur) => AppLanguageState.pick(en: en, ur: ur);

  // Onboarding
  static String get whoAreYou => _t('Who are you?', 'آپ کون ہیں؟');
  static String get selectYourRole => _t('Select your role', 'اپنا کردار منتخب کریں');
  static String get patient => _t('Patient', 'مریض');
  static String get patientSubtitle => _t('I take medications', 'میں دوائیں لیتا/لیتی ہوں');
  static String get caregiver => _t('Caregiver', 'دیکھ بھال کرنے والا');
  static String get caregiverSubtitle =>
      _t('I help manage medications', 'میں دوائیوں کا انتظام کرتا/کرتی ہوں');
  static String get doctor => _t('Doctor', 'ڈاکٹر');
  static String get doctorSubtitle =>
      _t('I review patient history', 'میں مریض کی تاریخ دیکھتا/دیکھتی ہوں');

  static String get continueWithPhone => _t('Continue with Phone', 'فون سے جاری رکھیں');
  static String get phoneSignInBlurb => _t(
    'Enter your mobile number to sign in or create an account. No SMS code required.',
    'سائن ان یا نیا اکاؤنٹ بنانے کے لیے اپنا موبائل نمبر درج کریں۔ ایس ایم ایس کوڈ نہیں چاہیے۔',
  );
  static String get phoneNumber => _t('Phone Number', 'فون نمبر');
  static String get continueBtn => _t('Continue', 'جاری رکھیں');
  static String get pleaseWait => _t('Please wait...', 'انتظار کریں...');

  // Patient home
  static String get todaysMedicines => _t("Today's Medicines", 'آج کی دوائیں');
  static String get settings => _t('Settings', 'ترتیبات');
  static String get myMedicines => _t('My medicines', 'میری دوائیں');
  static String get linkCode => _t('Link code', 'لنک کوڈ');
  static String get history => _t('History', 'تاریخ');
  static String get alerts => _t('Alerts', 'الرٹس');

  static String get taken => _t('Taken', 'لے لی');
  static String get missed => _t('Missed', 'چھوٹ گئی');
  static String get upcoming => _t('Upcoming', 'آنے والی');
  static String get dueNow => _t('Due now', 'اب لیں');
  static String get comingSoon => _t('Coming soon', 'جلد');

  // Settings
  static String get appSection => _t('App', 'ایپ');
  static String get medicinesSection => _t('Medicines', 'دوائیں');
  static String get myMedicinesManage =>
      _t('Add, edit, and manage your dose times', 'دوائیوں اور وقت شامل/تبدیل کریں');
  static String get inAppReminders => _t('In-app dose reminders', 'ایپ میں دوا کی یاددہانی');
  static String get inAppRemindersSub => _t(
        'Phone alarm at dose time (app open or closed)',
        'دوا کے وقت فون پر الارم (ایپ کھلی یا بند)',
      );
  static String get urduLanguage => _t('Urdu language', 'اردو زبان');
}
