import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/defaults.dart';
import '../models/auth_state.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  // Configure FlutterSecureStorage with explicit platform-specific options.
  // Android: Uses EncryptedSharedPreferences with AES/GCM.
  // iOS: Uses Keychain with kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
  //   which requires a device passcode and prevents backup extraction.
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.passcode,
    ),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyIdToken = 'id_token';
  static const _keyTokenType = 'token_type';
  static const _keyExpiresAt = 'expires_at';

  final ValueNotifier<AuthState> state =
      ValueNotifier<AuthState>(const AuthState());

  String? _issuerUrl;
  String? _clientId;
  String? _redirectUrl;
  String? _scopes;

  void configure({
    required String moodleBaseUrl,
    String? issuerUrl,
    String clientId = AppDefaults.oauth2ClientId,
    String redirectUrl = AppDefaults.oauth2RedirectUrl,
    String scopes = AppDefaults.oauth2Scopes,
  }) {
    _issuerUrl = issuerUrl ?? '$moodleBaseUrl/admin/oauth2/';
    _clientId = clientId;
    _redirectUrl = redirectUrl;
    _scopes = scopes;
  }

  Future<void> init() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final idToken = await _storage.read(key: _keyIdToken);
    final tokenType = await _storage.read(key: _keyTokenType);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);

    if (accessToken != null && refreshToken != null) {
      final expiresAt = expiresAtStr != null
          ? DateTime.tryParse(expiresAtStr)
          : null;

      state.value = AuthState(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        tokenType: tokenType,
        expiresAt: expiresAt,
        isAuthenticated: true,
      );

      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        await _tryRefresh();
      }
    }
  }

  Future<void> login() async {
    if (_issuerUrl == null || _clientId == null || _redirectUrl == null || _scopes == null) {
      state.value = state.value.copyWith(
        error: 'AuthService not configured. Call configure() first.',
      );
      return;
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId!,
          _redirectUrl!,
          issuer: _issuerUrl,
          scopes: _scopes!.split(' '),
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: '$_issuerUrl/authorize',
            tokenEndpoint: '$_issuerUrl/token',
          ),
          // Ensure ephemeral session (prevents SSO reuse across apps)
          externalUserAgent: ExternalUserAgent.ephemeralAsWebAuthenticationSession,
        ),
      );

      if (result.accessToken != null) {
        await _persistTokens(result);
        state.value = AuthState(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          idToken: result.idToken,
          tokenType: result.tokenType,
          expiresAt: result.accessTokenExpirationDateTime,
          isAuthenticated: true,
        );
      }
    } catch (e) {
      // Log full error for debugging but expose only a generic message to the UI
      debugPrint('Login failed: $e');
      state.value = state.value.copyWith(
        error: 'Authentication failed. Please check your credentials and try again.',
      );
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state.value = const AuthState();
  }

  Future<String?> getValidAccessToken() async {
    if (state.value.isExpired && state.value.refreshToken != null) {
      await _tryRefresh();
    }
    return state.value.accessToken;
  }

  Future<void> _tryRefresh() async {
    if (state.value.refreshToken == null) return;
    if (_issuerUrl == null || _clientId == null || _redirectUrl == null) return;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          _clientId!,
          _redirectUrl!,
          issuer: _issuerUrl,
          refreshToken: state.value.refreshToken,
          scopes: _scopes?.split(' '),
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: '$_issuerUrl/authorize',
            tokenEndpoint: '$_issuerUrl/token',
          ),
        ),
      );

      if (result.accessToken != null) {
        await _persistTokens(result);
        state.value = state.value.copyWith(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          idToken: result.idToken,
          tokenType: result.tokenType,
          expiresAt: result.accessTokenExpirationDateTime,
        );
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      state.value = state.value.copyWith(
        error: 'Session expired. Please log in again.',
      );
    }
  }

  Future<void> _persistTokens(TokenResponse result) async {
    final batch = <String, String>{};
    if (result.accessToken != null) batch[_keyAccessToken] = result.accessToken!;
    if (result.refreshToken != null) batch[_keyRefreshToken] = result.refreshToken!;
    if (result.idToken != null) batch[_keyIdToken] = result.idToken!;
    if (result.tokenType != null) batch[_keyTokenType] = result.tokenType!;
    if (result.accessTokenExpirationDateTime != null) {
      batch[_keyExpiresAt] = result.accessTokenExpirationDateTime!.toIso8601String();
    }
    for (final entry in batch.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }
}
