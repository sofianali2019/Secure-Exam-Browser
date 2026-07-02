import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/questions/question_card.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final PageController _pageController = PageController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final exam = appProvider.examProvider;

    if (appProvider.currentConfig == null && exam == null) {
      return _buildNoExam(context, appProvider);
    }

    // Config-only mode (QR/config key / admin launch without quiz ID).
    if (exam == null) {
      return _buildConfigOnlyMode(context, appProvider);
    }

    if (exam.isFinished) {
      return _buildFinishedView(exam, appProvider);
    }

    if (exam.isLoading && exam.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (exam.errorMessage != null && exam.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(exam.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
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
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(exam),
              _buildPageIndicator(exam),
              Expanded(child: _buildQuestionPages(exam)),
              _buildBottomBar(exam),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoExam(BuildContext context, AppProvider appProvider) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No active exam'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  appProvider.authState.isAuthenticated ? '/dashboard' : '/login',
                  (_) => false,
                );
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when exam is started via QR/config key (no native question data).
  Widget _buildConfigOnlyMode(BuildContext context, AppProvider appProvider) {
    final config = appProvider.currentConfig!;
    return PopScope(
      canPop: false,
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
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 72, color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    config.examTitle ?? 'Configured Exam',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Exam configuration loaded',
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  _infoRow('Duration', '${config.examDurationMinutes} min'),
                  _infoRow('Proctoring', config.proctoringEnabled ? 'Enabled' : 'Disabled'),
                  _infoRow('Fullscreen', config.fullscreenOnly ? 'Required' : 'Optional'),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('End Exam Session'),
                          content: const Text('Are you sure you want to end this exam session?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('End', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        await appProvider.endExam();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
                        }
                      }
                    },
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: const Text('End Exam Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTopBar(ExamProvider exam) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Secure Exam',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (exam.remainingSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: exam.remainingSeconds < 300
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: exam.remainingSeconds < 300
                        ? Colors.redAccent
                        : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    exam.formattedTime,
                    style: TextStyle(
                      color: exam.remainingSeconds < 300
                          ? Colors.redAccent
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ExamProvider exam) {
    final answered =
        exam.questions.where((q) => exam.getAnswer(q.slot).isNotEmpty).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Page ${exam.currentPage + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            '(${exam.questions.length} question${exam.questions.length == 1 ? '' : 's'})',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            '$answered/${exam.questions.length} answered',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPages(ExamProvider exam) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exam.questions.length,
      itemBuilder: (context, index) {
        final question = exam.questions[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: QuestionCard(
            question: question,
            currentAnswer: exam.getAnswer(question.slot),
            isFlagged: exam.isFlagged(question.slot),
            onAnswerChanged: (value) => exam.setAnswer(question.slot, value),
            onToggleFlag: () => exam.toggleFlag(question.slot),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(ExamProvider exam) {
    final page = _pageController.hasClients ? _pageController.page!.toInt() : 0;
    final isFirst = page == 0;
    final isLast = page >= exam.questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isFirst)
              TextButton.icon(
                onPressed: () {
                  _pageController.animateToPage(
                    page - 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
              )
            else
              const SizedBox(width: 80),
            const Spacer(),
            Text(
              '${page + 1} / ${exam.questions.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const Spacer(),
            if (!isLast)
              TextButton.icon(
                onPressed: () {
                  _pageController.animateToPage(
                    page + 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
              )
            else
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _handleSubmit(exam),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(ExamProvider exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit All Answers'),
        content: const Text(
          'Are you sure you want to submit all your answers?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSubmitting = true);
      await exam.submitAttempt();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildFinishedView(ExamProvider exam, AppProvider appProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Exam Submitted',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your answers have been submitted successfully.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await appProvider.endExam();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (_) => false,
                    );
                  }
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
