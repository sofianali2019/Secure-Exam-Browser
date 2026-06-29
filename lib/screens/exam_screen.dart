import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/app_provider.dart';
import '../models/lockdown_state.dart';
import '../widgets/lockdown_indicator.dart';
import '../widgets/proctoring_overlay.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  StreamSubscription<LockdownViolation>? _violationSub;
  StreamSubscription<Map<String, dynamic>>? _moodleEventSub;
  double _progress = 0;

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
      if (event['event'] == 'page_started') {
        setState(() => _progress = 0);
      } else if (event['event'] == 'page_finished') {
        setState(() => _progress = 1);
      }
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
          child: Column(
            children: [
              if (lockdownStatus == LockdownStatus.locked)
                LockdownIndicator(status: lockdownStatus),
              if (_progress > 0 && _progress < 1)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              Expanded(
                child: provider.webviewController != null
                    ? WebViewWidget(
                        controller: provider.webviewController!,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
              ),
              if (proctoringActive) const ProctoringOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
