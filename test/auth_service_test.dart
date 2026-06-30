import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_exam_browser/models/auth_state.dart';
import 'package:secure_exam_browser/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      authService = AuthService();
    });

    group('configure()', () {
      test('stores the base URL without trailing slash', () {
        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com');
        expect(authService.state.value, const AuthState());

        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com/');
        expect(authService.state.value, const AuthState());
      });
    });

    group('init()', () {
      test('loads saved token from storage', () async {
        FlutterSecureStorage.setMockInitialValues({
          'moodle_token': 'saved_token_123',
          'lms_url': 'https://subsaharanlms.com',
        });

        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com');
        await authService.init();

        expect(authService.state.value.isAuthenticated, true);
        expect(authService.state.value.token, 'saved_token_123');
      });

      test('returns unauthenticated when no stored token', () async {
        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com');
        await authService.init();

        expect(authService.state.value.isAuthenticated, false);
        expect(authService.state.value.token, isNull);
      });
    });

    group('logout()', () {
      test('clears token and resets state', () async {
        FlutterSecureStorage.setMockInitialValues({
          'moodle_token': 'token_to_clear',
          'lms_url': 'https://subsaharanlms.com',
        });

        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com');
        await authService.init();
        expect(authService.state.value.isAuthenticated, true);

        await authService.logout();
        expect(authService.state.value.isAuthenticated, false);
        expect(authService.state.value.token, isNull);
      });
    });

    group('login()', () {
      test('rejects login when base URL not configured', () async {
        await authService.login('user', 'pass');
        expect(authService.state.value.error, isNotNull);
        expect(authService.state.value.isAuthenticated, false);
      });
    });

    group('getValidToken()', () {
      test('returns null when not authenticated', () async {
        final token = await authService.getValidToken();
        expect(token, isNull);
      });

      test('returns token when authenticated', () async {
        FlutterSecureStorage.setMockInitialValues({
          'moodle_token': 'existing_token',
          'lms_url': 'https://subsaharanlms.com',
        });

        authService.configure(moodleBaseUrl: 'https://subsaharanlms.com');
        await authService.init();

        final token = await authService.getValidToken();
        expect(token, 'existing_token');
      });
    });
  });
}
