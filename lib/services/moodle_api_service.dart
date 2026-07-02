import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/course_info.dart';
import '../models/quiz_info.dart';
import '../models/quiz_attempt.dart';

class MoodleApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? httpStatus;
  const MoodleApiException(this.message, {this.errorCode, this.httpStatus});
  @override
  String toString() => 'MoodleApiException: $message (code: $errorCode)';
}

class MoodleApiService {
  final String baseUrl;
  final String token;
  final http.Client _client;
  /// Set true to log raw API responses for debugging course fetching.
  static bool debugCourseFetching = false;

  MoodleApiService({
    required this.baseUrl,
    required this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void dispose() => _client.close();

  Future<Map<String, dynamic>> _call({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    final body = <String, dynamic>{
      'wstoken': token,
      'wsfunction': function,
      'moodlewsrestformat': 'json',
    };
    if (params != null) body.addAll(params);

    final response = await _client.post(
      Uri.parse('$baseUrl/webservice/rest/server.php'),
      body: body,
    );

    if (response.statusCode != 200) {
      throw MoodleApiException(
        'HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      if (decoded.containsKey('exception')) {
        throw MoodleApiException(
          decoded['message'] as String? ?? 'Moodle error',
          errorCode: decoded['errorcode'] as String?,
        );
      }
      return decoded.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Future<List<CourseInfo>> getEnrolledCourses({
    String classification = 'all',
    int limit = 0,
    int offset = 0,
  }) async {
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getEnrolledCourses classification=$classification');
    }
    final data = await _call(
      function: 'core_course_get_enrolled_courses_by_timeline_classification',
      params: {
        'classification': classification,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getEnrolledCourses response keys=${data.keys}');
    }
    final coursesJson = data['courses'] as List<dynamic>? ?? [];
    return coursesJson
        .map((e) => CourseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourseInfo>> getUserCourses(int userId) async {
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getUserCourses userId=$userId');
    }
    final params = <String, dynamic>{
      'userid': userId.toString(),
    };
    final body = <String, dynamic>{
      'wstoken': token,
      'wsfunction': 'core_enrol_get_users_courses',
      'moodlewsrestformat': 'json',
    };
    body.addAll(params);

    final response = await _client.post(
      Uri.parse('$baseUrl/webservice/rest/server.php'),
      body: body,
    );

    if (response.statusCode != 200) {
      throw MoodleApiException(
        'HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getUserCourses raw response type=${decoded.runtimeType} body=${response.body.length < 500 ? response.body : '${response.body.substring(0, 500)}...'}');
    }
    if (decoded is Map && decoded.containsKey('exception')) {
      throw MoodleApiException(
        decoded['message'] as String? ?? 'Moodle error',
        errorCode: decoded['errorcode'] as String?,
      );
    }
    if (decoded is List) {
      return decoded
          .map((e) => CourseInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<int, List<QuizInfo>>> getCourseQuizzes(List<int> courseIds) async {
    final params = <String, dynamic>{};
    for (var i = 0; i < courseIds.length; i++) {
      params['courseids[$i]'] = courseIds[i].toString();
    }
    final data = await _call(
      function: 'mod_quiz_get_quizzes_by_courses',
      params: params,
    );
    final quizzesJson = data['quizzes'] as List<dynamic>? ?? [];
    final Map<int, List<QuizInfo>> result = {};
    for (final q in quizzesJson) {
      final quiz = QuizInfo.fromJson(q as Map<String, dynamic>);
      result.putIfAbsent(quiz.courseId, () => []).add(quiz);
    }
    return result;
  }

  Future<List<QuizAttempt>> getUserAttempts(int quizId, {String status = 'all'}) async {
    final data = await _call(
      function: 'mod_quiz_get_user_attempts',
      params: {
        'quizid': quizId.toString(),
        'status': status,
      },
    );
    final attemptsJson = data['attempts'] as List<dynamic>? ?? [];
    return attemptsJson
        .map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourseInfo>> getAllCourses() async {
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getAllCourses');
    }
    final body = <String, dynamic>{
      'wstoken': token,
      'wsfunction': 'core_course_get_courses',
      'moodlewsrestformat': 'json',
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/webservice/rest/server.php'),
      body: body,
    );

    if (response.statusCode != 200) {
      throw MoodleApiException(
        'HTTP ${response.statusCode}',
        httpStatus: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (debugCourseFetching) {
      debugPrint('MoodleApi: getAllCourses raw response type=${decoded.runtimeType} body=${response.body.length < 500 ? response.body : '${response.body.substring(0, 500)}...'}');
    }
    if (decoded is Map && decoded.containsKey('exception')) {
      throw MoodleApiException(
        decoded['message'] as String? ?? 'Moodle error',
        errorCode: decoded['errorcode'] as String?,
      );
    }
    if (decoded is List) {
      return decoded
          .map((e) => CourseInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getQuizAccessInfo(int quizId) async {
    return await _call(
      function: 'mod_quiz_get_quiz_access_information',
      params: {'quizid': quizId.toString()},
    );
  }

  /// Start a new quiz attempt.
  Future<Map<String, dynamic>> startAttempt(int quizId, {Map<String, String>? preflightData}) async {
    final params = <String, dynamic>{
      'quizid': quizId.toString(),
    };
    if (preflightData != null) {
      var i = 0;
      for (final entry in preflightData.entries) {
        params['preflightdata[$i][name]'] = entry.key;
        params['preflightdata[$i][value]'] = entry.value;
        i++;
      }
    }
    return await _call(
      function: 'mod_quiz_start_attempt',
      params: params,
    );
  }

  /// Get attempt data (questions) for a specific page.
  Future<Map<String, dynamic>> getAttemptData(int attemptId, int page) async {
    return await _call(
      function: 'mod_quiz_get_attempt_data',
      params: {
        'attemptid': attemptId.toString(),
        'page': page.toString(),
      },
    );
  }

  /// Process (save or submit) answers for an attempt page.
  Future<Map<String, dynamic>> processAttempt({
    required int attemptId,
    required List<Map<String, String>> data,
    bool finish = false,
    bool timeUp = false,
  }) async {
    final params = <String, dynamic>{
      'attemptid': attemptId.toString(),
      'finish': finish ? '1' : '0',
      'timeup': timeUp ? '1' : '0',
    };
    for (var i = 0; i < data.length; i++) {
      params['data[$i][name]'] = data[i]['name'] ?? '';
      params['data[$i][value]'] = data[i]['value'] ?? '';
    }
    return await _call(
      function: 'mod_quiz_process_attempt',
      params: params,
    );
  }

  /// Mark an attempt page as viewed.
  Future<Map<String, dynamic>> viewAttempt(int attemptId, int page) async {
    return await _call(
      function: 'mod_quiz_view_attempt',
      params: {
        'attemptid': attemptId.toString(),
        'page': page.toString(),
      },
    );
  }
}
