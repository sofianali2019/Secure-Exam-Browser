import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/exam_config.dart';

class ConfigService {
  static const _channel = MethodChannel('com.exambrowser/config');

  Future<ExamConfig?> parseSebConfig(String configJson) async {
    try {
      final decoded = jsonDecode(configJson) as Map<String, dynamic>;
      return _parseConfigMap(decoded);
    } catch (e) {
      debugPrint('Failed to parse SEB config: $e');
      return null;
    }
  }

  Future<ExamConfig?> decodeConfigKey(String configKey) async {
    // Try local base64 decode first (works on all platforms)
    try {
      final localConfig = _localBase64Decode(configKey);
      if (localConfig != null) return localConfig;
    } catch (_) {
      // Fall through to platform channel
    }

    // Then try platform channel
    try {
      final decoded = await _channel.invokeMethod<String>('decodeConfigKey', {
        'key': configKey,
      });
      if (decoded == null) return null;
      return parseSebConfig(decoded);
    } on PlatformException catch (e) {
      debugPrint('Config key decode failed (PlatformException): ${e.message}');
      return null;
    } on MissingPluginException catch (e) {
      debugPrint('Config key decode failed (MissingPluginException): ${e.message}');
      return null;
    }
  }

  /// Attempts to decode a config key using local base64 decoding.
  ExamConfig? _localBase64Decode(String key) {
    try {
      String decoded;
      try {
        decoded = utf8.decode(base64Url.decode(key));
      } catch (_) {
        decoded = utf8.decode(base64.decode(key));
      }
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return _parseConfigMap(json);
      }
      return null;
    } catch (e) {
      debugPrint('Local base64 decode failed: $e');
      return null;
    }
  }

  ExamConfig? _parseConfigMap(Map<String, dynamic> map) {
    final moodleUrl = map['moodleUrl'] as String? ??
        map['url'] as String? ??
        map['examUrl'] as String?;
    if (moodleUrl == null) return null;

    final lockdown = map['lockdown'] as Map<String, dynamic>? ?? {};

    var allowedDomains = <String>[];
    if (map['allowedDomains'] is List) {
      allowedDomains = (map['allowedDomains'] as List)
          .whereType<String>()
          .toList();
    } else if (map['permittedUrls'] is List) {
      allowedDomains = (map['permittedUrls'] as List)
          .map((e) => Uri.tryParse(e.toString())?.host ?? e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Enforce minimum lockdown: critical security features are always on.
    return ExamConfig(
      moodleUrl: moodleUrl,
      examDurationMinutes: map['duration'] as int? ??
          map['examDuration'] as int? ??
          60,
      proctoringEnabled: map['proctoring'] as bool? ??
          map['proctoringEnabled'] as bool? ??
          false,
      proctoringIntervalSeconds: map['proctoringInterval'] as int? ??
          map['proctoringIntervalSeconds'] as int? ??
          30,
      blockScreenshots: true,
      blockAppSwitching: true,
      blockNotifications: true,
      blockKeyboardShortcuts:
          (lockdown['blockKeyboardShortcuts'] as bool?) ??
          (map['allowShortcuts'] != true),
      blockRightClick:
          (lockdown['blockRightClick'] as bool?) ??
          (map['allowRightClick'] != true),
      fullscreenOnly: true,
      allowedDomains: allowedDomains,
      configKey: map['configKey'] as String?,
      examTitle: map['title'] as String? ?? map['examTitle'] as String?,
    );
  }

  Future<Map<String, dynamic>> fetchRemoteConfig(String configUrl) async {
    final uri = Uri.parse(configUrl);
    // Reject non-HTTPS URLs — exam config controls lockdown enforcement.
    if (uri.scheme != 'https') {
      debugPrint('Remote config fetch rejected: URL must use HTTPS, got ${uri.scheme}');
      return {};
    }
    final http.Response response;
    try {
      response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Remote config fetch failed: $e');
    }
    return {};
  }
}
