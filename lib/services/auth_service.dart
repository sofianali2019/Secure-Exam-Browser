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
  static const _keyBaseUrl = 'lms_url';

  final ValueNotifier<AuthState> state =
      ValueNotifier<AuthState>(const AuthState());

  String? _baseUrl;
  UserInfo? userInfo;
  static const _serviceName = 'moodle_mobile_app';

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

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/token.php'),
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
          state.value = AuthState(token: token, isAuthenticated: true);
          await fetchUserInfo();
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
    }
  }

  Future<void> fetchUserInfo() async {
    final token = state.value.token;
    if (_baseUrl == null || token == null) return;

    try {
      final response = await http.post(
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
    }
  }

  Future<void> logout() async {
    userInfo = null;
    await _storage.delete(key: _keyToken);
    state.value = const AuthState();
  }

  Future<String?> getValidToken() async {
    return state.value.token;
  }
}
