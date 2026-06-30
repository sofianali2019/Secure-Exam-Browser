class AppDefaults {
  AppDefaults._();

  static const String appName = 'Secure Exam Browser';
  static const String moodleBaseUrl = 'https://subsaharanlms.com';
  static const String oauth2ClientId = 'secure_exam_browser';
  static const String oauth2RedirectUrl =
      'com.exambrowser.secure_exam_browser://oauth2/callback';
  static const String oauth2Scopes = 'openid profile email';
  static const int defaultExamDurationMinutes = 60;
  static const int defaultProctoringIntervalSeconds = 30;
  static const String configKeyParam = 'seb_config_key';
  static const String issuerWellknown = '/.well-known/openid-configuration';
}
