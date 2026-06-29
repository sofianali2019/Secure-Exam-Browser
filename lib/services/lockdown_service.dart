import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exam_config.dart';
import '../models/lockdown_state.dart';

class LockdownService {
  static const _channel = MethodChannel('com.exambrowser/lockdown');
  static const _eventChannel = EventChannel('com.exambrowser/lockdown_events');

  final ValueNotifier<LockdownStatus> status =
      ValueNotifier<LockdownStatus>(LockdownStatus.idle);

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<LockdownViolation> _violationController =
      StreamController<LockdownViolation>.broadcast();

  Stream<LockdownViolation> get violations => _violationController.stream;
  bool get isLocked => status.value == LockdownStatus.locked;

  Future<void> startLockdown(ExamConfig config) async {
    status.value = LockdownStatus.locking;

    try {
      await _channel.invokeMethod('startLockdown', config.toJson());
      _eventSubscription?.cancel();
      _eventSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(_handlePlatformEvent);
      status.value = LockdownStatus.locked;
    } on PlatformException catch (e) {
      status.value = LockdownStatus.idle;
      debugPrint('Lockdown start failed: ${e.message}');
      rethrow;
    }
  }

  Future<void> stopLockdown() async {
    status.value = LockdownStatus.unlocking;

    try {
      await _channel.invokeMethod('stopLockdown');
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      status.value = LockdownStatus.idle;
    } on PlatformException catch (e) {
      debugPrint('Lockdown stop failed: ${e.message}');
      status.value = LockdownStatus.idle;
    }
  }

  Future<bool> isInLockdown() async {
    try {
      final result = await _channel.invokeMethod<bool>('isInLockdown');
      // Only accept an explicit bool; anything else (null, wrong type) = false
      if (result is bool) return result;
      return false;
    } on PlatformException {
      return false;
    }
  }

  void _handlePlatformEvent(dynamic event) {
    if (event is Map && event['type'] is String) {
      final violation = LockdownViolation(
        type: _parseViolationType(event['type'] as String),
        timestamp: DateTime.now(),
        detail: event['detail'] as String?,
      );
      _violationController.add(violation);
    }
  }

  ViolationType _parseViolationType(String type) {
    switch (type) {
      case 'screenshot':
        return ViolationType.screenshotAttempted;
      case 'app_switch':
        return ViolationType.appSwitchAttempted;
      case 'notification':
        return ViolationType.notificationReceived;
      case 'shortcut':
        return ViolationType.keyboardShortcutUsed;
      case 'right_click':
        return ViolationType.rightClickAttempted;
      case 'network_redirect':
        return ViolationType.networkRedirectBlocked;
      case 'task_manager':
        return ViolationType.taskManagerAttempted;
      default:
        debugPrint('Unknown violation type: $type');
        return ViolationType.screenshotAttempted;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _violationController.close();
  }
}
