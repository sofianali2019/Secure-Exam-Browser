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
  // core_course_get_courses
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> get allCourses => {
    'courses': [
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
    ],
    'warnings': [],
  };

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
  // Pre-encoded JSON strings
  // ---------------------------------------------------------------------------

  static String get enrolledCoursesJson => jsonEncode(enrolledCourses);
  static String get emptyCoursesJson => jsonEncode(emptyCourses);
  static String get courseQuizzesJson => jsonEncode(courseQuizzes);
  static String get emptyQuizzesJson => jsonEncode(emptyQuizzes);
  static String get userAttemptsJson => jsonEncode(userAttempts);
  static String get noAttemptsJson => jsonEncode(noAttempts);
  static String get allCoursesJson => jsonEncode(allCourses);
  static String get quizAccessInfoJson => jsonEncode(quizAccessInfo);
  static String get moodleExceptionJson => jsonEncode(moodleException);
  static String get invalidTokenErrorJson => jsonEncode(invalidTokenError);
}
