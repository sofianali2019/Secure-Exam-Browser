import 'dart:async';
import 'package:flutter/material.dart';

/// A compact countdown timer that displays remaining exam time in MM:SS.
///
/// Turns orange when < 5 minutes remain, red when < 1 minute remains.
/// Shows a warning dialog at the 5-minute mark and fires [onTimeExpired]
/// when the countdown reaches zero.
class ExamTimer extends StatefulWidget {
  final int durationMinutes;
  final DateTime startTime;
  final VoidCallback onTimeExpired;

  const ExamTimer({
    super.key,
    required this.durationMinutes,
    required this.startTime,
    required this.onTimeExpired,
  });

  /// Utility to show the "Time Expired" dialog from the parent callback.
  static void showTimeExpiredDialog(
    BuildContext context,
    VoidCallback onSubmit,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Time's Up!",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Your exam time has expired.\n'
          'Your answers will be submitted automatically.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onSubmit();
            },
            child: const Text(
              'Submit Now',
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _endTime;
  int _remainingSeconds = 0;
  bool _hasWarned = false;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _endTime = widget.startTime.add(Duration(minutes: widget.durationMinutes));
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final remaining = _endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      if (!_hasExpired) {
        _hasExpired = true;
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        widget.onTimeExpired();
      }
      return;
    }
    setState(() => _remainingSeconds = remaining.inSeconds);

    if (!_hasWarned && _remainingSeconds <= 300 && _remainingSeconds > 0) {
      _hasWarned = true;
      _showWarning();
    }
  }

  void _showWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Time Warning',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'You have less than 5 minutes remaining.\n'
          'Make sure to submit your answers.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Continue Exam',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color get _timerColor {
    if (_remainingSeconds <= 60) return Colors.redAccent;
    if (_remainingSeconds <= 300) return Colors.orangeAccent;
    return Colors.white;
  }

  String get _formatted {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _remainingSeconds <= 300 ? Icons.timer_off : Icons.timer_outlined,
          size: 14,
          color: _timerColor,
        ),
        const SizedBox(width: 4),
        Text(
          _formatted,
          style: TextStyle(
            color: _timerColor,
            fontSize: 14,
            fontWeight:
                _remainingSeconds <= 300 ? FontWeight.bold : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
