import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secure_exam_browser/models/quiz_attempt.dart';
import 'package:secure_exam_browser/services/moodle_api_service.dart';

import 'fixtures/moodle_responses.dart';

  /// Options bag for [MockClient] that lets each test control behaviour without
  /// writing a full handler closure.
  class MockClientOptions {
    /// When set, the handler returns [overrideBody] only for this function.
    final String? functionOverride;

    /// The response body to return for the overridden function.
    /// Must be JSON-encodable (Map, List, etc.).
    final Object? overrideBody;

    /// Non-200 status to force (applied to all responses).
    final int? statusCodeOverride;

    /// When `true` the client throws a [http.ClientException].
    final bool networkError;

    const MockClientOptions({
      this.functionOverride,
      this.overrideBody,
      this.statusCodeOverride,
      this.networkError = false,
    });
  }

/// Builds a [MockClient] handler that routes on `wsfunction` from the POST
/// body and supports per-test overrides via [MockClientOptions].
Future<http.Response> Function(http.Request) _mockHandler([
  MockClientOptions options = const MockClientOptions(),
]) {
  return (request) async {
    if (options.networkError) {
      throw http.ClientException('Connection refused', request.url);
    }

    final function = request.bodyFields['wsfunction'] ?? '';

    // Per-function override takes precedence
    if (options.functionOverride != null &&
        function == options.functionOverride &&
        options.overrideBody != null) {
      return http.Response(
        jsonEncode(options.overrideBody),
        options.statusCodeOverride ?? 200,
      );
    }

    // Global status override for HTTP error tests
    if (options.statusCodeOverride != null &&
        options.functionOverride == null) {
      return http.Response('{}', options.statusCodeOverride!);
    }

    switch (function) {
      case 'core_course_get_enrolled_courses_by_timeline_classification':
        return http.Response(
          MoodleFixtures.enrolledCoursesJson,
          options.statusCodeOverride ?? 200,
        );
      case 'mod_quiz_get_quizzes_by_courses':
        return http.Response(
          MoodleFixtures.courseQuizzesJson,
          options.statusCodeOverride ?? 200,
        );
      case 'mod_quiz_get_user_attempts':
        return http.Response(
          MoodleFixtures.userAttemptsJson,
          options.statusCodeOverride ?? 200,
        );
      case 'core_enrol_get_users_courses':
        return http.Response(
          MoodleFixtures.userCoursesJson,
          options.statusCodeOverride ?? 200,
        );
      case 'core_course_get_courses':
        return http.Response(
          MoodleFixtures.allCoursesJson,
          options.statusCodeOverride ?? 200,
        );
      case 'mod_quiz_get_quiz_access_information':
        return http.Response(
          MoodleFixtures.quizAccessInfoJson,
          options.statusCodeOverride ?? 200,
        );
      default:
        return http.Response(
          jsonEncode({'error': 'unknown function'}),
          400,
        );
    }
  };
}

void main() {
  const testBaseUrl = 'https://test.moodle.edu';
  const testToken = 'valid_token_abc123';

  group('MoodleApiService', () {
    group('getEnrolledCourses', () {
      test('returns list of enrolled courses on success', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final courses = await api.getEnrolledCourses();

        expect(courses, hasLength(2));
        expect(courses[0].id, 3);
        expect(courses[0].fullName, 'Mathematics 101');
        expect(courses[0].shortName, 'MAT101');
        expect(courses[0].isFavourite, isFalse);
        expect(courses[1].id, 5);
        expect(courses[1].fullName, 'Physics 101');
        expect(courses[1].isFavourite, isTrue);
      });

      test('returns empty list when no courses enrolled', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride:
              'core_course_get_enrolled_courses_by_timeline_classification',
          overrideBody: MoodleFixtures.emptyCourses,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final courses = await api.getEnrolledCourses();

        expect(courses, isEmpty);
      });

      test('throws MoodleApiException on HTTP error', () async {
        final client =
            MockClient(_mockHandler(MockClientOptions(
          statusCodeOverride: 500,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        expect(
          () => api.getEnrolledCourses(),
          throwsA(isA<MoodleApiException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 500'),
          )),
        );
      });

      test('throws MoodleApiException on Moodle exception response',
          () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride:
              'core_course_get_enrolled_courses_by_timeline_classification',
          overrideBody: MoodleFixtures.moodleException,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        expect(
          () => api.getEnrolledCourses(),
          throwsA(isA<MoodleApiException>().having(
            (e) => e.message,
            'message',
            contains('This quiz is not available'),
          )),
        );
      });

      test('throws ClientException on network error', () async {
        final client =
            MockClient(_mockHandler(MockClientOptions(networkError: true)));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        expect(
          () => api.getEnrolledCourses(),
          throwsA(isA<http.ClientException>()),
        );
      });
    });

    group('getUserCourses', () {
      test('returns list of enrolled courses for a user', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final courses = await api.getUserCourses(5);

        expect(courses, hasLength(2));
        expect(courses[0].id, 3);
        expect(courses[0].fullName, 'Mathematics 101');
        expect(courses[1].id, 5);
        expect(courses[1].fullName, 'Physics 101');
      });

      test('returns empty list when user has no courses', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'core_enrol_get_users_courses',
          overrideBody: MoodleFixtures.emptyUserCourses,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final courses = await api.getUserCourses(999);

        expect(courses, isEmpty);
      });

      test('throws MoodleApiException on Moodle error', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'core_enrol_get_users_courses',
          overrideBody: MoodleFixtures.moodleException,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        expect(
          () => api.getUserCourses(1),
          throwsA(isA<MoodleApiException>()),
        );
      });
    });

    group('getCourseQuizzes', () {
      test('returns map of quizzes keyed by course ID', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final result = await api.getCourseQuizzes([3]);

        expect(result, containsPair(3, hasLength(1)));
        final quizzes = result[3]!;
        expect(quizzes[0].id, 42);
        expect(quizzes[0].name, 'Midterm Exam');
        expect(quizzes[0].courseId, 3);
        expect(quizzes[0].coursemodule, 123);
        expect(quizzes[0].timeLimit, 3600);
        expect(quizzes[0].attemptsAllowed, 1);
        expect(quizzes[0].hasQuestions, isTrue);
      });

      test('returns empty map when no quizzes exist', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'mod_quiz_get_quizzes_by_courses',
          overrideBody: MoodleFixtures.emptyQuizzes,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final result = await api.getCourseQuizzes([99]);

        expect(result, isEmpty);
      });

      test('throws MoodleApiException on invalid token', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'mod_quiz_get_quizzes_by_courses',
          overrideBody: MoodleFixtures.invalidTokenError,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: 'expired_token',
          client: client,
        );

        expect(
          () => api.getCourseQuizzes([1]),
          throwsA(isA<MoodleApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'invalidtoken',
          )),
        );
      });
    });

    group('getUserAttempts', () {
      test('returns list of attempts for a quiz', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final attempts = await api.getUserAttempts(42);

        expect(attempts, hasLength(1));
        expect(attempts[0].id, 987);
        expect(attempts[0].quizId, 42);
        expect(attempts[0].userId, 5);
        expect(attempts[0].state, AttemptState.finished);
        expect(attempts[0].timeStart, 1704154000);
        expect(attempts[0].timeFinish, 1704157000);
        expect(attempts[0].sumGrades, 85.5);
        expect(attempts[0].grade, 85.5);
      });

      test('returns empty list when no attempts exist', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'mod_quiz_get_user_attempts',
          overrideBody: MoodleFixtures.noAttempts,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final attempts = await api.getUserAttempts(999);

        expect(attempts, isEmpty);
      });
    });

    group('getAllCourses', () {
      test('returns list of all courses', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final courses = await api.getAllCourses();

        expect(courses, hasLength(1));
        expect(courses[0].id, 1);
        expect(courses[0].fullName, 'Computer Science 101');
        expect(courses[0].shortName, 'CS101');
      });

      test('throws MoodleApiException on error response', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'core_course_get_courses',
          overrideBody: MoodleFixtures.moodleException,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        expect(
          () => api.getAllCourses(),
          throwsA(isA<MoodleApiException>()),
        );
      });
    });

    group('getQuizAccessInfo', () {
      test('returns access info map for a quiz', () async {
        final client = MockClient(_mockHandler());
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        final info = await api.getQuizAccessInfo(42);

        expect(info['canattempt'], isTrue);
        expect(info['attempts'], 1);
      });

      test('throws MoodleApiException on error response', () async {
        final client = MockClient(_mockHandler(MockClientOptions(
          functionOverride: 'mod_quiz_get_quiz_access_information',
          overrideBody: MoodleFixtures.invalidTokenError,
        )));
        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: 'expired_token',
          client: client,
        );

        expect(
          () => api.getQuizAccessInfo(999),
          throwsA(isA<MoodleApiException>()),
        );
      });
    });

    group('request construction', () {
      test('sends wstoken and wsfunction in request body', () async {
        String? capturedToken;
        String? capturedFunction;

        final client = MockClient((request) async {
          capturedToken = request.bodyFields['wstoken'];
          capturedFunction = request.bodyFields['wsfunction'];
          return http.Response(MoodleFixtures.enrolledCoursesJson, 200);
        });

        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        await api.getEnrolledCourses();

        expect(capturedToken, testToken);
        expect(
            capturedFunction,
            'core_course_get_enrolled_courses_by_timeline_classification');
      });

      test('sends requests to correct endpoint URL', () async {
        Uri? capturedUri;

        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(MoodleFixtures.enrolledCoursesJson, 200);
        });

        final api = MoodleApiService(
          baseUrl: testBaseUrl,
          token: testToken,
          client: client,
        );

        await api.getEnrolledCourses();

        expect(capturedUri?.path, '/webservice/rest/server.php');
        expect(capturedUri?.host, 'test.moodle.edu');
      });
    });
  });
}
