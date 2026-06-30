class AuthState {
  final String? token;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.token,
    this.isAuthenticated = false,
    this.error,
  });
}
