import 'package:flutter/material.dart';
import '../models/lockdown_state.dart';

class LockdownIndicator extends StatelessWidget {
  final LockdownStatus status;

  const LockdownIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case LockdownStatus.locked:
        color = Colors.green;
        label = 'Exam Lockdown Active';
        break;
      case LockdownStatus.locking:
        color = Colors.orange;
        label = 'Activating Lockdown...';
        break;
      case LockdownStatus.unlocking:
        color = Colors.orange;
        label = 'Releasing Lockdown...';
        break;
      case LockdownStatus.violation:
        color = Colors.red;
        label = 'Lockdown Violation Detected';
        break;
      default:
        color = Colors.grey;
        label = 'Lockdown Inactive';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.9),
      child: Row(
        children: [
          Icon(
            status == LockdownStatus.locked
                ? Icons.lock
                : status == LockdownStatus.violation
                    ? Icons.warning
                    : Icons.lock_open,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status == LockdownStatus.locking)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
