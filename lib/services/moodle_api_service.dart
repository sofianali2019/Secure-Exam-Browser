import 'dart:convert';
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
    final data = await _call(
      function: 'core_course_get_enrolled_courses_by_timeline_classification',
      params: {
        'classification': classification,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    final coursesJson = data['courses'] as List<dynamic>? ?? [];
    return coursesJson
        .map((e) => CourseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = await _call(function: 'core_course_get_courses');
    final coursesJson = data['courses'] as List<dynamic>? ?? [];
    return coursesJson
        .map((e) => CourseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getQuizAccessInfo(int quizId) async {
    return await _call(
      function: 'mod_quiz_get_quiz_access_information',
      params: {'quizid': quizId.toString()},
    );
  }
}
