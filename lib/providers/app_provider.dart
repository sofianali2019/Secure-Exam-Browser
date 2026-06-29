import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/exam_config.dart';
import '../models/auth_state.dart';
import '../models/lockdown_state.dart';
import '../services/auth_service.dart';
import '../services/lockdown_service.dart';
import '../services/webview_service.dart';
import '../services/proctoring_service.dart';
import '../services/config_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService authService = AuthService();
  final LockdownService lockdownService = LockdownService();
  final WebviewService webviewService = WebviewService();
  final ProctoringService proctoringService = ProctoringService();
  final ConfigService configService = ConfigService();

  ExamConfig? currentConfig;
  bool _isInitialized = false;
  bool _isLoginInProgress = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoginInProgress => _isLoginInProgress;
  String? get errorMessage => _errorMessage;

  /// Convenience accessors so screens don't reach into services directly.
  AuthState get authState => authService.state.value;
  LockdownStatus get lockdownStatus => lockdownService.status.value;
  bool get isLocked => lockdownService.isLocked;
  bool get isProctoringActive => proctoringService.isActive.value;
  int get snapshotsTaken => proctoringService.snapshotsTaken.value;
  Stream<LockdownViolation> get violations => lockdownService.violations;
  Stream<Map<String, dynamic>> get moodleEvents => webviewService.moodleEvents;
  WebViewController? get webviewController => webviewService.controller;

  Future<void> initialize({required String moodleBaseUrl}) async {
    try {
      authService.configure(moodleBaseUrl: moodleBaseUrl);
      await authService.init();
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
      debugPrint('AppProvider.initialize error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> login() async {
    if (_isLoginInProgress) return;
    _isLoginInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.login();
      if (authService.state.value.error != null) {
        _errorMessage = authService.state.value.error;
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
      notifyListeners();

      await lockdownService.startLockdown(config);

      webviewService.buildController(config: config);

      if (authService.state.value.accessToken != null) {
        await webviewService.injectToken(authService.state.value.accessToken!);
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
    webviewService.dispose();
    proctoringService.dispose();
    lockdownService.dispose();
    super.dispose();
  }
}
