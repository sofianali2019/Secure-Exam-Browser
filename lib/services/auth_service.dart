import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/auth_state.dart';
import '../models/user_info.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.passcode,
    ),
  );

  static const _keyToken = 'moodle_token';
  static const _keyPrivateToken = 'moodle_private_token';
  static const _keyBaseUrl = 'lms_url';

  final ValueNotifier<AuthState> state =
      ValueNotifier<AuthState>(const AuthState());

  String? _baseUrl;
  UserInfo? userInfo;
  String? _privateToken;
  static const _serviceName = 'moodle_mobile_app';
  /// User-Agent that Moodle requires to return privatetoken from /login/token.php.
  static const _moodleUserAgent = 'MoodleMobile';

  final http.Client Function() _clientFactory;

  AuthService({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? (() => http.Client());

  String? get baseUrl => _baseUrl;

  void configure({required String moodleBaseUrl}) {
    final base = moodleBaseUrl.endsWith('/')
        ? moodleBaseUrl.substring(0, moodleBaseUrl.length - 1)
        : moodleBaseUrl;
    _baseUrl = base;
  }

  Future<void> init() async {
    final token = await _storage.read(key: _keyToken);
    final baseUrl = await _storage.read(key: _keyBaseUrl);
    _privateToken = await _storage.read(key: _keyPrivateToken);
    if (token != null && baseUrl != null) {
      _baseUrl = baseUrl;
      state.value = AuthState(token: token, isAuthenticated: true);
    }
  }

  Future<void> login(String username, String password) async {
    if (_baseUrl == null) {
      state.value = const AuthState(
        error: 'LMS URL not configured. Enter your LMS URL first.',
      );
      return;
    }

    final client = _clientFactory();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/login/token.php'),
        headers: {'User-Agent': _moodleUserAgent},
        body: {
          'username': username,
          'password': password,
          'service': _serviceName,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('token')) {
          final token = data['token'] as String;
          await _storage.write(key: _keyToken, value: token);
          await _storage.write(key: _keyBaseUrl, value: _baseUrl);
          // Moodle only returns privatetoken when User-Agent includes MoodleMobile
          if (data.containsKey('privatetoken')) {
            _privateToken = data['privatetoken'] as String?;
            if (_privateToken != null) {
              await _storage.write(key: _keyPrivateToken, value: _privateToken);
            }
          }
          state.value = AuthState(token: token, isAuthenticated: true);
          await fetchUserInfo(client: client);
        } else {
          final errorMsg = data['error'] as String? ?? 'Unknown error';
          state.value = AuthState(error: errorMsg);
        }
      } else {
        state.value = const AuthState(
          error: 'Login failed. Check your credentials.',
        );
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      state.value = const AuthState(
        error: 'Connection failed. Check your network and LMS URL.',
      );
    } finally {
      client.close();
    }
  }

  Future<void> fetchUserInfo({http.Client? client}) async {
    final token = state.value.token;
    if (_baseUrl == null || token == null) return;

    final c = client ?? _clientFactory();
    try {
      final response = await c.post(
        Uri.parse('$_baseUrl/webservice/rest/server.php'),
        body: {
          'wstoken': token,
          'wsfunction': 'core_webservice_get_site_info',
          'moodlewsrestformat': 'json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        userInfo = UserInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('fetchUserInfo failed: $e');
    } finally {
      if (client == null) c.close();
    }
  }

  Future<void> logout() async {
    userInfo = null;
    _privateToken = null;
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyPrivateToken);
    state.value = const AuthState();
  }

  Future<String?> getValidToken() async {
    return state.value.token;
  }

  /// Calls tool_mobile_get_autologin_key to get a one-time key for WebView auth.
  /// Returns null if the key cannot be obtained (rate-limited, missing privatetoken).
  Future<String?> getAutologinKey() async {
    final token = state.value.token;
    if (_baseUrl == null || token == null || _privateToken == null) {
      debugPrint('getAutologinKey: missing baseUrl, token, or privatetoken');
      return null;
    }
    final client = _clientFactory();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/webservice/rest/server.php'),
        headers: {'User-Agent': _moodleUserAgent},
        body: {
          'wstoken': token,
          'privatetoken': _privateToken!,
          'wsfunction': 'tool_mobile_get_autologin_key',
          'moodlewsrestformat': 'json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('exception')) {
          debugPrint('getAutologinKey error: ${data['errorcode']} ${data['message']}');
          return null;
        }
        return data['key'] as String?;
      }
    } catch (e) {
      debugPrint('getAutologinKey failed: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Wraps [targetUrl] with Moodle's autologin endpoint for WebView authentication.
  /// Falls back to returning [targetUrl] unchanged if the autologin key cannot be obtained.
  Future<String> buildAutologinUrl(String targetUrl) async {
    final userId = userInfo?.userId;
    if (userId == null) {
      debugPrint('buildAutologinUrl: no userId, returning raw URL');
      return targetUrl;
    }
    final key = await getAutologinKey();
    if (key == null) {
      debugPrint('buildAutologinUrl: no autologin key, returning raw URL');
      return targetUrl;
    }
    final resolved = '$_baseUrl/admin/tool/mobile/autologin.php'
        '?userid=$userId&key=$key&urltogo=${Uri.encodeComponent(targetUrl)}';
    debugPrint('buildAutologinUrl: resolved to $resolved');
    return resolved;
  }
}
