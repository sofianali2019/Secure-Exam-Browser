enum LockdownStatus { idle, locking, locked, unlocking, violation }

enum ViolationType {
  screenshotAttempted,
  appSwitchAttempted,
  notificationReceived,
  keyboardShortcutUsed,
  rightClickAttempted,
  networkRedirectBlocked,
  taskManagerAttempted,
}

class LockdownViolation {
  final ViolationType type;
  final DateTime timestamp;
  final String? detail;

  const LockdownViolation({
    required this.type,
    required this.timestamp,
    this.detail,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'detail': detail,
      };
}
