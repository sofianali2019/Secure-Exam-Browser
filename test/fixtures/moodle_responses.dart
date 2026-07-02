import 'dart:convert';

/// Test fixtures for Moodle REST API responses.
///
/// Provides both [Map] responses and pre-encoded JSON strings for use in
/// service tests via [MockClient].
class MoodleFixtures {
  // ---------------------------------------------------------------------------
  // core_course_get_enrolled_courses_by_timeline_classification
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> get enrolledCourses => {
    'courses': [
      {
        'id': 3,
        'shortname': 'MAT101',
        'fullname': 'Mathematics 101',
        'displayname': 'Mathematics 101',
        'summary': '<p>Introduction to Algebra</p>',
        'startdate': 1704067200,
        'enddate': 1711843200,
        'coursecategory': 'Science',
        'progress': 60,
        'visible': true,
        'hidden': false,
        'isfavourite': false,
        'courseimage': '',
        'timeaccess': 1712345678,
      },
      {
        'id': 5,
        'shortname': 'PHY101',
        'fullname': 'Physics 101',
        'displayname': 'Physics 101',
        'summary': '<p>Mechanics</p>',
        'startdate': 1704067200,
        'enddate': 1711843200,
        'coursecategory': 'Science',
        'progress': 30,
        'visible': true,
        'hidden': false,
        'isfavourite': true,
        'courseimage': 'https://example.com/phy.jpg',
        'timeaccess': 1712345679,
      },
    ],
    'warnings': [],
  };

  static Map<String, dynamic> get emptyCourses => {
    'courses': [],
    'warnings': [],
  };

  // ---------------------------------------------------------------------------
  // mod_quiz_get_quizzes_by_courses
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> get courseQuizzes => {
    'quizzes': [
      {
        'id': 42,
        'coursemodule': 123,
        'course': 3,
        'name': 'Midterm Exam',
        'intro': '<p>Chapters 1-6</p>',
        'timeopen': 1704153600,
        'timeclose': 1704240000,
        'timelimit': 3600,
        'attempts': 1,
        'gradepass': 60.0,
        'sumgrades': 100.0,
        'hasquestions': true,
        'visible': true,
      },
    ],
    'warnings': [],
  };

  static Map<String, dynamic> get emptyQuizzes => {
    'quizzes': [],
    'warnings': [],
  };

  // ---------------------------------------------------------------------------
  // mod_quiz_get_user_attempts
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> get userAttempts => {
    'attempts': [
      {
        'id': 987,
        'quiz': 42,
        'userid': 5,
        'attempt': 1,
        'timestart': 1704154000,
        'timefinish': 1704157000,
        'state': 'finished',
        'sumgrades': 85.5,
        'grade': 85.5,
      },
    ],
    'warnings': [],
  };

  static Map<String, dynamic> get noAttempts => {
    'attempts': [],
    'warnings': [],
  };

  // ---------------------------------------------------------------------------
  // core_course_get_courses (returns a JSON array, not a map)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // core_enrol_get_users_courses (returns a JSON array)
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> get userCourses => [
    {
      'id': 3,
      'shortname': 'MAT101',
      'fullname': 'Mathematics 101',
      'displayname': 'Mathematics 101',
      'summary': '<p>Introduction to Algebra</p>',
      'startdate': 1704067200,
      'enddate': 1711843200,
      'coursecategory': 'Science',
      'visible': true,
    },
    {
      'id': 5,
      'shortname': 'PHY101',
      'fullname': 'Physics 101',
      'displayname': 'Physics 101',
      'summary': '<p>Mechanics</p>',
      'startdate': 1704067200,
      'enddate': 1711843200,
      'coursecategory': 'Science',
      'visible': true,
    },
  ];

  static List<Map<String, dynamic>> get allCourses => [
    {
      'id': 1,
      'shortname': 'CS101',
      'fullname': 'Computer Science 101',
      'displayname': 'CS 101',
      'summary': 'Intro to CS',
      'coursecategory': 'Science',
      'startdate': 1704067200,
      'enddate': 1711843200,
      'isfavourite': false,
      'hidden': false,
    },
  ];

  // ---------------------------------------------------------------------------
  // mod_quiz_get_quiz_access_information
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> get quizAccessInfo => {
    'canattempt': true,
    'canpreview': false,
    'canreviewmyattempts': true,
    'canmanage': false,
    'attempts': 1,
    'activeattempt': null,
    'warnings': [],
  };

  // ---------------------------------------------------------------------------
  // Error responses (all use the `exception` key)
  // ---------------------------------------------------------------------------

  /// Generic Moodle exception.
  static Map<String, dynamic> get moodleException => {
    'exception': 'moodle_quiz_exception',
    'errorcode': 'notavailable',
    'message': 'This quiz is not available',
  };

  /// Invalid / expired token.
  static Map<String, dynamic> get invalidTokenError => {
    'exception': 'webservice_access_exception',
    'errorcode': 'invalidtoken',
    'message': 'Invalid token - token not found',
  };

  // ---------------------------------------------------------------------------
  // core_webservice_get_site_info + login token responses
  // ---------------------------------------------------------------------------

  /// Login token response from /login/token.php (with privatetoken).
  static Map<String, dynamic> get loginTokenResponse => {
    'token': 'moodle_token_abc123',
    'privatetoken': 'private_token_xyz789',
  };

  /// Response for tool_mobile_get_autologin_key.
  static Map<String, dynamic> get autologinKeyResponse => {
    'key': 'autologin_key_abc123',
    'autologinurl': 'https://subsaharanlms.com/admin/tool/mobile/autologin.php?userid=5&key=autologin_key_abc123',
  };

  /// Site info response for user info.
  static Map<String, dynamic> get siteInfoResponse => {
    'siteid': 'site1',
    'sitename': 'Test Site',
    'username': 'testuser',
    'firstname': 'Test',
    'lastname': 'User',
    'fullname': 'Test User',
    'language': 'en',
    'userid': 5,
    'siteurl': 'https://subsaharanlms.com',
    'userpictureurl': 'https://subsaharanlms.com/user/pix.php/5/f1.jpg',
    'functions': [],
    'downloadfiles': 1,
    'uploadfiles': 1,
    'release': '4.5.0',
    'version': '2025032400',
    'mobilecssurl': '',
    'advancedfeatures': [],
    'usercanmanageownfiles': true,
    'userissiteadmin': false,
    'supportpagecontents': '',
  };

  // ---------------------------------------------------------------------------
  // Pre-encoded JSON strings
  // ---------------------------------------------------------------------------

  static String get enrolledCoursesJson => jsonEncode(enrolledCourses);
  static String get emptyCoursesJson => jsonEncode(emptyCourses);
  static String get courseQuizzesJson => jsonEncode(courseQuizzes);
  static String get emptyQuizzesJson => jsonEncode(emptyQuizzes);
  static String get userAttemptsJson => jsonEncode(userAttempts);
  static String get noAttemptsJson => jsonEncode(noAttempts);
  static String get userCoursesJson => jsonEncode(userCourses);
  static List<Map<String, dynamic>> get emptyUserCourses => [];
  static String get allCoursesJson => jsonEncode(allCourses);
  static String get quizAccessInfoJson => jsonEncode(quizAccessInfo);
  static String get moodleExceptionJson => jsonEncode(moodleException);
  static String get invalidTokenErrorJson => jsonEncode(invalidTokenError);
  static String get loginTokenResponseJson => jsonEncode(loginTokenResponse);
  static String get autologinKeyResponseJson => jsonEncode(autologinKeyResponse);
  static String get siteInfoResponseJson => jsonEncode(siteInfoResponse);
}
