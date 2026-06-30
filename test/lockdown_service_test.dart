import 'package:flutter_test/flutter_test.dart';
import 'package:secure_exam_browser/models/auth_state.dart';
import 'package:secure_exam_browser/models/exam_config.dart';
import 'package:secure_exam_browser/models/lockdown_state.dart';

void main() {
  group('ExamConfig', () {
    test('parses from JSON correctly', () {
      final json = {
        'moodleUrl': 'https://subsaharanlms.com',
        'examDurationMinutes': 90,
        'proctoringEnabled': true,
        'proctoringIntervalSeconds': 15,
      };
      final config = ExamConfig.fromJson(json);
      expect(config.moodleUrl, 'https://subsaharanlms.com');
      expect(config.examDurationMinutes, 90);
      expect(config.proctoringEnabled, true);
      expect(config.proctoringIntervalSeconds, 15);
    });

    test('effectiveAllowedDomains falls back to moodleUrl host', () {
      const config = ExamConfig(moodleUrl: 'https://moodle.test.edu');
      expect(config.effectiveAllowedDomains, ['moodle.test.edu']);
    });

    test('effectiveAllowedDomains uses explicit list when provided', () {
      const config = ExamConfig(
        moodleUrl: 'https://moodle.test.edu',
        allowedDomains: ['moodle.test.edu', 'cdn.moodle.test.edu'],
      );
      expect(config.effectiveAllowedDomains, [
        'moodle.test.edu',
        'cdn.moodle.test.edu',
      ]);
    });

    test('toJson and fromJson round-trip', () {
      const original = ExamConfig(
        moodleUrl: 'https://subsaharanlms.com',
        examDurationMinutes: 45,
        proctoringEnabled: true,
        blockScreenshots: false,
        configKey: 'ABC123',
      );
      final json = original.toJson();
      final restored = ExamConfig.fromJson(json);
      expect(restored.moodleUrl, original.moodleUrl);
      expect(restored.examDurationMinutes, original.examDurationMinutes);
      expect(restored.proctoringEnabled, original.proctoringEnabled);
      expect(restored.blockScreenshots, original.blockScreenshots);
      expect(restored.configKey, original.configKey);
    });
  });

  group('LockdownViolation', () {
    test('creates with correct type and timestamp', () {
      final violation = LockdownViolation(
        type: ViolationType.screenshotAttempted,
        timestamp: DateTime(2026, 6, 27),
        detail: 'Screen recording detected',
      );
      expect(violation.type, ViolationType.screenshotAttempted);
      expect(violation.detail, 'Screen recording detected');
      expect(violation.toJson()['type'], 'screenshotAttempted');
    });

    test('toJson returns correct map', () {
      final time = DateTime(2026, 6, 27, 12, 0, 0);
      final violation = LockdownViolation(
        type: ViolationType.appSwitchAttempted,
        timestamp: time,
      );
      final json = violation.toJson();
      expect(json['type'], 'appSwitchAttempted');
      expect(json['timestamp'], time.toIso8601String());
      expect(json.containsKey('detail'), true);
      expect(json['detail'], isNull);
    });

    test('supports all violation types', () {
      for (final type in ViolationType.values) {
        final violation = LockdownViolation(
          type: type,
          timestamp: DateTime.now(),
        );
        expect(violation.type, type);
        expect(violation.toJson()['type'], type.name);
      }
    });
  });

  group('AuthState', () {
    test('defaults to unauthenticated', () {
      const state = AuthState();
      expect(state.isAuthenticated, false);
      expect(state.token, isNull);
      expect(state.error, isNull);
    });

    test('can be created with token and authenticated', () {
      const state = AuthState(token: 'moodle_token_123', isAuthenticated: true);
      expect(state.isAuthenticated, true);
      expect(state.token, 'moodle_token_123');
      expect(state.error, isNull);
    });

    test('can carry an error message', () {
      const state = AuthState(error: 'Invalid credentials');
      expect(state.isAuthenticated, false);
      expect(state.token, isNull);
      expect(state.error, 'Invalid credentials');
    });
  });
}
