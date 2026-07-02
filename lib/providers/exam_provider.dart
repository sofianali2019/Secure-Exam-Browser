import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/question_data.dart';
import '../models/quiz_attempt.dart';
import '../services/moodle_api_service.dart';

class ExamProvider extends ChangeNotifier {
  final MoodleApiService api;

  ExamProvider({required this.api});

  // -- Attempt state --
  QuizAttempt? _attempt;
  int _currentPage = 0;
  int _lastPage = 0;
  List<QuestionData> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isFinished = false;

  // -- Answers --
  final Map<int, String> _userAnswers = {}; // slot -> answer value
  final Set<int> _flaggedSlots = {};

  // -- Timer --
  Timer? _timer;
  int _remainingSeconds = 0;

  // -- Getters --
  QuizAttempt? get attempt => _attempt;
  int get attemptId => _attempt?.id ?? 0;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  List<QuestionData> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isFinished => _isFinished;
  int get remainingSeconds => _remainingSeconds;
  bool get hasPreviousPage => _currentPage > 0;
  bool get hasNextPage => _currentPage < _lastPage;

  String getAnswer(int slot) => _userAnswers[slot] ?? '';

  bool isFlagged(int slot) => _flaggedSlots.contains(slot);

  // -- Timer formatting --
  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -- Core actions --

  Future<void> startAttempt(int quizId, {Map<String, String>? preflight}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await api.startAttempt(quizId, preflightData: preflight);
      final attemptJson = result['attempt'] as Map<String, dynamic>?;
      if (attemptJson == null) {
        throw Exception('No attempt returned');
      }
      final attempt = QuizAttempt.fromJson(attemptJson);
      _attempt = attempt;

      await _loadPage(0);
    } catch (e) {
      _errorMessage = 'Failed to start attempt: $e';
      debugPrint('ExamProvider.startAttempt error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPage(int page) async {
    if (_attempt == null) return;

    try {
      final data = await api.getAttemptData(_attempt!.id, page);
      _currentPage = page;

      final attemptJson = data['attempt'] as Map<String, dynamic>?;
      if (attemptJson != null) {
        _attempt = QuizAttempt.fromJson(attemptJson);
      }

      final questionsJson = data['questions'] as List<dynamic>? ?? [];
      _questions = questionsJson
          .map((q) => QuestionData.fromApiJson(q as Map<String, dynamic>))
          .toList();

      _lastPage = _attempt?.isInProgress == true ? 999 : 0;

      // Calculate remaining time
      final timeLimit = attemptJson?['timelimit'] as int? ?? 0;
      final timeStart = _attempt?.timeStart ?? 0;
      if (timeLimit > 0 && timeStart > 0) {
        final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - timeStart;
        _remainingSeconds = (timeLimit - elapsed).clamp(0, timeLimit);
        _startTimer();
      } else {
        _remainingSeconds = 0;
      }

      await api.viewAttempt(_attempt!.id, page);
    } catch (e) {
      _errorMessage = 'Failed to load page $page: $e';
      debugPrint('ExamProvider._loadPage error: $e');
    }
  }

  void setAnswer(int slot, String value) {
    _userAnswers[slot] = value;
    notifyListeners();
  }

  void toggleFlag(int slot) {
    if (_flaggedSlots.contains(slot)) {
      _flaggedSlots.remove(slot);
    } else {
      _flaggedSlots.add(slot);
    }
    notifyListeners();
  }

  Future<void> saveCurrentPage() async {
    await _submitPage(finish: false);
  }

  Future<void> nextPage() async {
    await _submitPage(finish: false);
    if (_currentPage < _lastPage) {
      await _loadPage(_currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await _loadPage(_currentPage - 1);
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 0 && page <= _lastPage) {
      await _submitPage(finish: false);
      await _loadPage(page);
    }
  }

  Future<void> submitAttempt() async {
    await _submitPage(finish: true);
  }

  Future<void> _submitPage({required bool finish}) async {
    if (_attempt == null || _isSubmitting) return;
    _isSubmitting = true;
    notifyListeners();

    try {
      // Build data array from user answers for current questions
      final data = <Map<String, String>>[];
      for (final q in _questions) {
        final answer = _userAnswers[q.slot];
        final seqField = <String, String>{
          'name': 'sequencecheck_${q.slot}',
          'value': q.sequenceCheck.toString(),
        };
        data.add(seqField);

        if (answer != null && answer.isNotEmpty) {
          data.addAll(q.buildSubmissionData(answer));
        }
      }

      final result = await api.processAttempt(
        attemptId: _attempt!.id,
        data: data,
        finish: finish,
      );

      if (finish) {
        _isFinished = true;
        _stopTimer();
      }

      // Update attempt state
      final attemptJson = result['attempt'] as Map<String, dynamic>?;
      if (attemptJson != null) {
        _attempt = QuizAttempt.fromJson(attemptJson);
      }
    } catch (e) {
      _errorMessage = 'Failed to submit: $e';
      debugPrint('ExamProvider._submitPage error: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // -- Timer --
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
      } else {
        _stopTimer();
        // Auto-submit when time runs out
        _submitPage(finish: true);
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
