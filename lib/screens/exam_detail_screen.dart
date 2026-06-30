import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_config.dart';
import '../models/quiz_info.dart';
import '../providers/app_provider.dart';

class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  QuizInfo? _quiz;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is QuizInfo && _quiz == null) {
      _quiz = args;
    }
  }

  Future<void> _startExam() async {
    final quiz = _quiz;
    if (quiz == null) return;

    final provider = context.read<AppProvider>();
    try {
      final config = ExamConfig(
        moodleUrl: quiz.viewUrl(provider.moodleBaseUrl),
        examDurationMinutes: (quiz.timeLimit ?? 3600) ~/ 60,
        examTitle: quiz.name,
        proctoringEnabled: true,
        blockScreenshots: true,
        blockAppSwitching: true,
        blockNotifications: true,
        fullscreenOnly: true,
      );

      await provider.startExam(config);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/exam');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start exam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B60),
        title: Text(
          quiz?.name ?? 'Exam Details',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: quiz == null
          ? const Center(
              child: Text(
                'No exam information available',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course name
                  Text(
                    'Course Quiz',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Quiz title
                  Text(
                    quiz.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (quiz.intro != null && quiz.intro!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quiz.intro!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Time limit - large centered
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quiz.timeLimitFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time Limit',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Attempts info
                  _infoCard(
                    icon: Icons.assignment,
                    title: 'Attempts',
                    value: quiz.attemptsAllowed > 0
                        ? '${quiz.attemptsAllowed} allowed'
                        : 'Unlimited',
                  ),
                  const SizedBox(height: 12),
                  // Available dates
                  _infoCard(
                    icon: Icons.date_range,
                    title: 'Availability',
                    value: quiz.isAvailable ? 'Currently available' : 'Not available',
                  ),
                  const SizedBox(height: 32),
                  // Lockdown features with green checkmarks
                  const Text(
                    'Lockdown Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _lockdownFeature(Icons.check_circle, 'Screenshots blocked'),
                  const SizedBox(height: 8),
                  _lockdownFeature(Icons.check_circle, 'App switching blocked'),
                  const SizedBox(height: 8),
                  _lockdownFeature(Icons.check_circle, 'Notifications blocked'),
                  const SizedBox(height: 8),
                  _lockdownFeature(Icons.check_circle, 'Fullscreen mode enforced'),
                  const SizedBox(height: 8),
                  _lockdownFeature(Icons.check_circle, 'Proctoring enabled'),
                  const SizedBox(height: 40),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _startExam,
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text(
                        'Start Exam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _lockdownFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(
            '$title: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
