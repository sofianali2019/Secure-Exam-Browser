import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/app_provider.dart';
import '../models/lockdown_state.dart';
import '../widgets/lockdown_indicator.dart';
import '../widgets/proctoring_overlay.dart';
import '../widgets/exam_timer.dart';
import '../widgets/exam_info_overlay.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  StreamSubscription<LockdownViolation>? _violationSub;
  StreamSubscription<Map<String, dynamic>>? _moodleEventSub;
  double _progress = 0;
  bool _hasWebViewError = false;
  String? _webViewErrorDescription;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupListeners());
  }

  void _setupListeners() {
    final provider = context.read<AppProvider>();

    _violationSub = provider.violations.listen((v) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lockdown violation: ${v.type.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    _moodleEventSub = provider.moodleEvents.listen((event) {
      if (!mounted) return;
      final eventType = event['event'] as String?;

      switch (eventType) {
        case 'page_started':
          setState(() {
            _progress = 0;
            _hasWebViewError = false;
            _webViewErrorDescription = null;
          });
          break;
        case 'page_finished':
          setState(() => _progress = 1);
          break;
        case 'resource_error':
          setState(() {
            _hasWebViewError = true;
            _webViewErrorDescription =
                event['description'] as String? ?? 'Failed to load page';
          });
          break;
        case 'quiz_submit_clicked':
          debugPrint('Quiz submit button clicked by user');
          break;
        case 'timer_warning':
          debugPrint('Moodle timer warning detected: ${event['source']}');
          break;
        case 'bridge_ready':
          debugPrint('Moodle JS bridge initialized');
          break;
        case 'navigation_blocked':
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation blocked by lockdown rules'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        case 'visibility_change':
          if (event['visible'] == false && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exam tab visibility changed'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }
    });
  }

  Future<void> _handleSubmitQuiz() async {
    final provider = context.read<AppProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          'Submit Quiz',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: const Text(
          'Are you sure you want to submit your quiz?\n\n'
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSubmitting = true);
      final success = await provider.submitQuiz();
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Quiz submission initiated'
                  : 'Could not find submit button. Please submit manually.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleTimeExpired() {
    if (!mounted) return;
    ExamTimer.showTimeExpiredDialog(context, () {
      _handleSubmitQuiz();
    });
  }

  @override
  void dispose() {
    _violationSub?.cancel();
    _moodleEventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lockdownStatus = provider.lockdownStatus;
    final proctoringActive = provider.isProctoringActive;
    final isExamActive = provider.webviewController != null;
    final config = provider.currentConfig;

    return PopScope(
      canPop: !provider.isLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot exit during an active exam'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Main column layout ──
              Column(
                children: [
                  // Top toolbar (when exam is active)
                  if (isExamActive) _buildExamToolbar(provider, config),

                  // Lockdown status indicator (non-locked states)
                  if (isExamActive &&
                      lockdownStatus != LockdownStatus.locked)
                    LockdownIndicator(status: lockdownStatus),

                  // Progress indicator
                  if (_progress > 0 && _progress < 1)
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),

                  // Main content area
                  Expanded(
                    child: isExamActive
                        ? _buildExamContent(provider)
                        : _buildWelcomeState(provider),
                  ),

                  // Proctoring overlay
                  if (proctoringActive) const ProctoringOverlay(),
                ],
              ),

              // ── Submit FAB (above proctoring) ──
              if (isExamActive)
                Positioned(
                  right: 16,
                  bottom: 80,
                  child: AnimatedOpacity(
                    opacity: _hasWebViewError ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton.small(
                      onPressed: _hasWebViewError ? null : _handleSubmitQuiz,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A237E),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A237E),
                              ),
                            )
                          : const Icon(Icons.check),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the compact exam toolbar with lock icon, title, timer, and info button.
  Widget _buildExamToolbar(AppProvider provider, dynamic config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Lock icon
          Icon(
            provider.isLocked ? Icons.lock : Icons.lock_open,
            color: provider.isLocked ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),

          // Exam title (truncated)
          Expanded(
            child: Text(
              provider.examTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Timer
          if (provider.examStartTime != null && config != null)
            ExamTimer(
              durationMinutes: config.examDurationMinutes,
              startTime: provider.examStartTime!,
              onTimeExpired: _handleTimeExpired,
            ),

          const SizedBox(width: 4),

          // Info button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              iconSize: 20,
              onPressed: () => ExamInfoOverlay.show(
                context: context,
                examTitle: provider.examTitle,
                moodleUrl: config?.moodleUrl ?? '',
                durationMinutes: config?.examDurationMinutes ?? 0,
                startTime: provider.examStartTime ?? DateTime.now(),
                proctoringEnabled: config?.proctoringEnabled ?? false,
                blockScreenshots: config?.blockScreenshots ?? false,
                blockAppSwitching: config?.blockAppSwitching ?? false,
                blockNotifications: config?.blockNotifications ?? false,
                fullscreenOnly: config?.fullscreenOnly ?? false,
              ),
              padding: EdgeInsets.zero,
              tooltip: 'Exam Information',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the WebView content area with error overlay if needed.
  Widget _buildExamContent(AppProvider provider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _hasWebViewError
          ? _buildConnectionLostOverlay(provider)
          : Stack(
              key: const ValueKey('webview'),
              children: [
                WebViewWidget(
                  controller: provider.webviewController!,
                ),
                // Submission overlay
                if (_isSubmitting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Submitting quiz...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Connection lost overlay with error info and retry button.
  Widget _buildConnectionLostOverlay(AppProvider provider) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Lost',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _webViewErrorDescription ??
                  'Unable to load the exam page.\nPlease check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryLoad() async {
    final provider = context.read<AppProvider>();
    setState(() {
      _hasWebViewError = false;
      _webViewErrorDescription = null;
    });
    if (provider.currentConfig != null) {
      await provider.webviewService
          .loadExam(provider.currentConfig!.moodleUrl);
    }
  }

  /// Welcome state shown when no exam is running.
  Widget _buildWelcomeState(AppProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Signed in to ${provider.moodleBaseUrl}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'No exam is running',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Return to the dashboard to start an exam.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                provider.authState.isAuthenticated
                    ? '/dashboard'
                    : '/login',
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
