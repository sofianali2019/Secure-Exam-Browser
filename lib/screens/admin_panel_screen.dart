import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_info.dart';
import '../models/exam_config.dart';
import '../models/quiz_info.dart';
import '../providers/app_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dashboard data
  int _totalCourses = 0;
  int _totalQuizzes = 0;
  bool _isLoadingDashboard = true;

  // Courses data
  List<CourseInfo> _allCourses = [];
  bool _isLoadingCourses = true;
  String? _coursesError;

  // Exams data
  CourseInfo? _selectedCourse;
  List<QuizInfo> _courseQuizzes = [];
  bool _isLoadingQuizzes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDashboard();
    _loadAllCourses();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {}); // Refresh state on tab switch
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------
  Future<void> _loadDashboard() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final provider = context.read<AppProvider>();
      final courses = await provider.fetchCourses();
      int quizCount = 0;
      // Count quizzes across courses (limit to first few to avoid heavy load)
      for (final course in courses.take(10)) {
        try {
          final quizzes = await provider.fetchQuizzes(course.id);
          quizCount += quizzes.length;
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _totalCourses = courses.length;
          _totalQuizzes = quizCount;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Courses
  // ---------------------------------------------------------------------------
  Future<void> _loadAllCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _coursesError = null;
    });
    try {
      final provider = context.read<AppProvider>();
      final courses = await provider.fetchAllCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coursesError = 'Failed to load courses: $e';
          _isLoadingCourses = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Exams
  // ---------------------------------------------------------------------------
  Future<void> _loadQuizzesForCourse(CourseInfo course) async {
    setState(() {
      _selectedCourse = course;
      _isLoadingQuizzes = true;
    });
    try {
      final provider = context.read<AppProvider>();
      final quizzes = await provider.fetchQuizzes(course.id);
      if (mounted) {
        setState(() {
          _courseQuizzes = quizzes;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingQuizzes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quizzes: $e')),
        );
      }
    }
  }

  void _showLockdownConfig(QuizInfo quiz) {
    final urlController = TextEditingController(
      text: '${context.read<AppProvider>().moodleBaseUrl}/mod/quiz/view.php?id=${quiz.id}',
    );
    final durationController = TextEditingController(
      text: (quiz.timeLimit ?? 0) > 0
          ? ((quiz.timeLimit ?? 3600) / 60).ceil().toString()
          : '60',
    );
    bool proctoring = true;
    bool blockScreenshots = true;
    bool blockAppSwitching = true;
    bool blockNotifications = true;
    bool blockKeyboardShortcuts = true;
    bool blockRightClick = true;
    bool fullscreenOnly = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A237E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lockdown Config: ${quiz.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Exam URL',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF1A237E)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _toggleTile('Enable Proctoring', proctoring, (v) {
                  setSheetState(() => proctoring = v);
                }),
                _toggleTile('Block Screenshots', blockScreenshots, (v) {
                  setSheetState(() => blockScreenshots = v);
                }),
                _toggleTile('Block App Switching', blockAppSwitching, (v) {
                  setSheetState(() => blockAppSwitching = v);
                }),
                _toggleTile('Block Notifications', blockNotifications, (v) {
                  setSheetState(() => blockNotifications = v);
                }),
                _toggleTile('Block Keyboard Shortcuts', blockKeyboardShortcuts, (v) {
                  setSheetState(() => blockKeyboardShortcuts = v);
                }),
                _toggleTile('Block Right Click', blockRightClick, (v) {
                  setSheetState(() => blockRightClick = v);
                }),
                _toggleTile('Fullscreen Only', fullscreenOnly, (v) {
                  setSheetState(() => fullscreenOnly = v);
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final config = ExamConfig(
                        moodleUrl: urlController.text.trim(),
                        examDurationMinutes:
                            int.tryParse(durationController.text.trim()) ?? 60,
                        examTitle: quiz.name,
                        proctoringEnabled: proctoring,
                        proctoringIntervalSeconds: 30,
                        blockScreenshots: blockScreenshots,
                        blockAppSwitching: blockAppSwitching,
                        blockNotifications: blockNotifications,
                        blockKeyboardShortcuts: blockKeyboardShortcuts,
                        blockRightClick: blockRightClick,
                        fullscreenOnly: fullscreenOnly,
                      );
                      Navigator.of(ctx).pop();
                      _previewAndLaunchConfig(config);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  void _previewAndLaunchConfig(ExamConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text('Config Ready', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _adminDetailRow('Exam', config.examTitle ?? 'Untitled'),
            _adminDetailRow('Duration', '${config.examDurationMinutes} min'),
            _adminDetailRow('Proctoring', config.proctoringEnabled ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final provider = context.read<AppProvider>();
                await provider.startExam(config);
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/exam');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Launch Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final userInfo = provider.authService.userInfo;
    final isAdmin = userInfo?.isSiteAdmin ?? false;

    if (provider.authState.isAuthenticated && !isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A237E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151B60),
          title: const Text(
            'Access Denied',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Administrator access required',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B60),
        title: const Text(
          'Administrator Panel',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.school), text: 'Courses'),
            Tab(icon: Icon(Icons.quiz), text: 'Exams'),
            Tab(icon: Icon(Icons.monitor), text: 'Monitor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildCoursesTab(),
          _buildExamsTab(),
          _buildMonitorTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard Tab
  // ---------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    if (_isLoadingDashboard) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading stats...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.school,
                  label: 'Courses',
                  value: '$_totalCourses',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.quiz,
                  label: 'Quizzes',
                  value: '$_totalQuizzes',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.admin_panel_settings,
                  label: 'Role',
                  value: 'Administrator',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.link,
                  label: 'LMS',
                  value: context.read<AppProvider>().moodleBaseUrl
                      .replaceAll('https://', ''),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Stats'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Courses Tab
  // ---------------------------------------------------------------------------
  Widget _buildCoursesTab() {
    if (_isLoadingCourses) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading courses...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_coursesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _coursesError!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAllCourses,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allCourses.length,
        itemBuilder: (context, index) {
          final course = _allCourses[index];
          final isSelected = _selectedCourse?.id == course.id;
          return Card(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? const BorderSide(color: Colors.blueAccent)
                  : BorderSide.none,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                course.fullName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                course.shortName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Switch to exams tab and load quizzes
                  _loadQuizzesForCourse(course);
                  _tabController.animateTo(2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Quizzes', style: TextStyle(fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exams Tab
  // ---------------------------------------------------------------------------
  Widget _buildExamsTab() {
    if (_selectedCourse == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back,
              size: 48,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a course from the Courses tab',
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoadingQuizzes) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading quizzes...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white.withValues(alpha: 0.05),
          child: Text(
            'Quizzes for: ${_selectedCourse!.fullName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: _courseQuizzes.isEmpty
              ? Center(
                  child: Text(
                    'No quizzes found for this course',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courseQuizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _courseQuizzes[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quiz.timeLimitFormatted,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.tune,
                                color: Colors.white70,
                              ),
                              tooltip: 'Lockdown Config',
                              onPressed: () => _showLockdownConfig(quiz),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Monitor Tab
  // ---------------------------------------------------------------------------
  Widget _buildMonitorTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Live Monitoring',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Real-time exam monitoring will be available\nin a future update.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
