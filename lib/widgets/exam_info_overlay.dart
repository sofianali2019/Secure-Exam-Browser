import 'dart:async';
import 'package:flutter/material.dart';

/// A slide-up panel that shows exam details during an active exam.
///
/// Displays exam title, host URL, time remaining, and the status
/// of lockdown security features. Shown as a modal bottom sheet
/// via [ExamInfoOverlay.show].
class ExamInfoOverlay {
  /// Shows the overlay as a modal bottom sheet with the given exam details.
  static void show({
    required BuildContext context,
    required String examTitle,
    required String moodleUrl,
    required int durationMinutes,
    required DateTime startTime,
    required bool proctoringEnabled,
    required bool blockScreenshots,
    required bool blockAppSwitching,
    required bool blockNotifications,
    required bool fullscreenOnly,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A237E),
      isScrollControlled: true,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExamInfoSheet(
        examTitle: examTitle,
        moodleUrl: moodleUrl,
        durationMinutes: durationMinutes,
        startTime: startTime,
        proctoringEnabled: proctoringEnabled,
        blockScreenshots: blockScreenshots,
        blockAppSwitching: blockAppSwitching,
        blockNotifications: blockNotifications,
        fullscreenOnly: fullscreenOnly,
      ),
    );
  }
}

class _ExamInfoSheet extends StatefulWidget {
  final String examTitle;
  final String moodleUrl;
  final int durationMinutes;
  final DateTime startTime;
  final bool proctoringEnabled;
  final bool blockScreenshots;
  final bool blockAppSwitching;
  final bool blockNotifications;
  final bool fullscreenOnly;

  const _ExamInfoSheet({
    required this.examTitle,
    required this.moodleUrl,
    required this.durationMinutes,
    required this.startTime,
    required this.proctoringEnabled,
    required this.blockScreenshots,
    required this.blockAppSwitching,
    required this.blockNotifications,
    required this.fullscreenOnly,
  });

  @override
  State<_ExamInfoSheet> createState() => _ExamInfoSheetState();
}

class _ExamInfoSheetState extends State<_ExamInfoSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Exam title ──
            Text(
              widget.examTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // ── Moodle URL ──
            Text(
              widget.moodleUrl,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // ── Timer section ──
            Center(
              child: Column(
                children: [
                  Text(
                    'Time Remaining',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RemainingTimeDisplay(
                    durationMinutes: widget.durationMinutes,
                    startTime: widget.startTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Security features ──
            Text(
              'SECURITY FEATURES',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _FeatureRow(
              icon: Icons.videocam,
              label: 'Camera Proctoring',
              active: widget.proctoringEnabled,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.screenshot_monitor,
              label: 'Screenshots Blocked',
              active: widget.blockScreenshots,
              blocked: true,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.swap_horiz,
              label: 'App Switching Blocked',
              active: widget.blockAppSwitching,
              blocked: true,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.notifications_off,
              label: 'Notifications Blocked',
              active: widget.blockNotifications,
              blocked: true,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.fullscreen,
              label: 'Fullscreen Mode',
              active: widget.fullscreenOnly,
              blocked: true,
            ),
            const SizedBox(height: 24),

            // ── Return button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Return to Exam',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A single feature row with icon, label, and status indicator.
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool blocked;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.active,
    this.blocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: active
              ? Colors.greenAccent
              : Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          blocked
              ? Icons.lock
              : (active
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked),
          size: 18,
          color: active
              ? Colors.greenAccent
              : Colors.white.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

/// Lightweight countdown text used inside the info overlay.
/// Runs its own timer so the overlay stays current.
class _RemainingTimeDisplay extends StatefulWidget {
  final int durationMinutes;
  final DateTime startTime;

  const _RemainingTimeDisplay({
    required this.durationMinutes,
    required this.startTime,
  });

  @override
  State<_RemainingTimeDisplay> createState() => _RemainingTimeDisplayState();
}

class _RemainingTimeDisplayState extends State<_RemainingTimeDisplay> {
  Timer? _timer;
  late DateTime _endTime;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _endTime =
        widget.startTime.add(Duration(minutes: widget.durationMinutes));
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final remaining = _endTime.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remainingSeconds =
          remaining.isNegative ? 0 : remaining.inSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remainingSeconds <= 60) return Colors.redAccent;
    if (_remainingSeconds <= 300) return Colors.orangeAccent;
    return Colors.white;
  }

  String get _formatted {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60)
        .toString()
        .padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    if (_remainingSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatted,
      style: TextStyle(
        color: _timerColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
