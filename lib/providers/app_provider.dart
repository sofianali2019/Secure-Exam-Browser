import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/defaults.dart';
import '../models/course_info.dart';
import '../models/exam_config.dart';
import '../models/auth_state.dart';
import '../models/lockdown_state.dart';
import '../models/quiz_info.dart';
import '../services/auth_service.dart';
import '../services/lockdown_service.dart';
import '../services/webview_service.dart';
import '../services/proctoring_service.dart';
import '../services/config_service.dart';
import '../services/moodle_api_service.dart';

class AppProvider extends ChangeNotifier {
  static const _lmsUrlKey = 'lms_url';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final AuthService authService = AuthService();
  final LockdownService lockdownService = LockdownService();
  final WebviewService webviewService = WebviewService();
  final ProctoringService proctoringService = ProctoringService();
  final ConfigService configService = ConfigService();

  MoodleApiService? _moodleApi;

  ExamConfig? currentConfig;
  DateTime? examStartTime;
  bool _isInitialized = false;
  bool _isLoginInProgress = false;
  String? _errorMessage;
  String _moodleBaseUrl = AppDefaults.moodleBaseUrl;

  /// State tracking fields for course/quiz data.
  bool isLoadingCourses = false;
  List<CourseInfo> enrolledCourses = [];
  Map<int, List<QuizInfo>> courseQuizzes = {};

  bool get isInitialized => _isInitialized;
  bool get isLoginInProgress => _isLoginInProgress;
  String? get errorMessage => _errorMessage;
  String get moodleBaseUrl => _moodleBaseUrl;

  /// Convenience accessors so screens don't reach into services directly.
  AuthState get authState => authService.state.value;
  LockdownStatus get lockdownStatus => lockdownService.status.value;
  bool get isLocked => lockdownService.isLocked;
  bool get isProctoringActive => proctoringService.isActive.value;
  int get snapshotsTaken => proctoringService.snapshotsTaken.value;
  Stream<LockdownViolation> get violations => lockdownService.violations;
  Stream<Map<String, dynamic>> get moodleEvents => webviewService.moodleEvents;
  WebViewController? get webviewController => webviewService.controller;

  /// The exam title from the current config, or a fallback.
  String get examTitle => currentConfig?.examTitle ?? 'Untitled Exam';

  MoodleApiService? get moodleApi => _moodleApi;

  /// Build the MoodleApiService when authenticated.
  void _ensureMoodleApi() {
    final token = authService.state.value.token;
    if (token != null && _moodleApi == null) {
      _moodleApi = MoodleApiService(
        baseUrl: moodleBaseUrl,
        token: token,
      );
    }
  }

  /// Dispose and rebuild the MoodleApiService (e.g. after login/config change).
  void _rebuildMoodleApi() {
    _moodleApi?.dispose();
    _moodleApi = null;
    _ensureMoodleApi();
  }

  // ---------------------------------------------------------------------------
  // Moodle API high-level methods for screens
  // ---------------------------------------------------------------------------

  /// Fetch the current user's enrolled courses.
  Future<List<CourseInfo>> fetchCourses() async {
    _ensureMoodleApi();
    if (_moodleApi == null) return [];
    isLoadingCourses = true;
    notifyListeners();
    try {
      final courses = await _moodleApi!.getEnrolledCourses();
      enrolledCourses = courses;
      return courses;
    } finally {
      isLoadingCourses = false;
      notifyListeners();
    }
  }

  /// Fetch all courses (admin only).
  Future<List<CourseInfo>> fetchAllCourses() async {
    _ensureMoodleApi();
    if (_moodleApi == null) return [];
    return _moodleApi!.getAllCourses();
  }

  /// Fetch quizzes for a given course.
  Future<List<QuizInfo>> fetchQuizzes(int courseId) async {
    _ensureMoodleApi();
    if (_moodleApi == null) return [];
    final result = await _moodleApi!.getCourseQuizzes([courseId]);
    final quizzes = result[courseId] ?? [];
    courseQuizzes[courseId] = quizzes;
    return quizzes;
  }

  /// Create an ExamConfig from a QuizInfo and start the exam.
  Future<void> startExamFromMoodle(QuizInfo quiz) async {
    _ensureMoodleApi();
    final config = ExamConfig(
      moodleUrl: quiz.viewUrl(moodleBaseUrl),
      examDurationMinutes: (quiz.timeLimit ?? 3600) ~/ 60,
      examTitle: quiz.name,
      proctoringEnabled: true,
      blockScreenshots: true,
      blockAppSwitching: true,
      blockNotifications: true,
      blockKeyboardShortcuts: true,
      blockRightClick: true,
      fullscreenOnly: true,
    );
    await startExam(config);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle methods
  // ---------------------------------------------------------------------------

  Future<void> initialize({String? moodleBaseUrl}) async {
    try {
      final saved = await _storage.read(key: _lmsUrlKey);
      _moodleBaseUrl = moodleBaseUrl ?? saved ?? AppDefaults.moodleBaseUrl;
      authService.configure(moodleBaseUrl: _moodleBaseUrl);
      await authService.init();
      if (authService.state.value.isAuthenticated) {
        _ensureMoodleApi();
      }
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
      debugPrint('AppProvider.initialize error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> setLmsUrl(String url) async {
    _moodleBaseUrl = url;
    await _storage.write(key: _lmsUrlKey, value: url);
    authService.configure(moodleBaseUrl: url);
    _rebuildMoodleApi();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    if (_isLoginInProgress) return;
    _isLoginInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.login(username, password);
      if (authService.state.value.error != null) {
        _errorMessage = authService.state.value.error;
      } else {
        _ensureMoodleApi();
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
    } finally {
      _isLoginInProgress = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _moodleApi?.dispose();
      _moodleApi = null;
      await authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> startExam(ExamConfig config) async {
    try {
      currentConfig = config;
      examStartTime = DateTime.now();
      notifyListeners();

      await lockdownService.startLockdown(config);

      webviewService.buildController(config: config);

      if (authService.state.value.token != null) {
        await webviewService.injectToken(authService.state.value.token!);
      }

      await webviewService.loadExam(config.moodleUrl);

      if (config.proctoringEnabled) {
        await proctoringService.start(config: config);
      }

      notifyListeners();
    } catch (e) {
      // Rollback lockdown if it was started
      await lockdownService.stopLockdown();
      currentConfig = null;
      _errorMessage = 'Failed to start exam: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> submitQuiz() async {
    return webviewService.submitQuiz();
  }

  Future<void> endExam() async {
    try {
      await proctoringService.stop();
    } catch (e) {
      debugPrint('Proctoring stop error: $e');
    }
    try {
      await lockdownService.stopLockdown();
    } catch (e) {
      debugPrint('Lockdown stop error: $e');
    }
    webviewService.dispose();
    currentConfig = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _moodleApi?.dispose();
    webviewService.dispose();
    proctoringService.dispose();
    lockdownService.dispose();
    super.dispose();
  }
}
