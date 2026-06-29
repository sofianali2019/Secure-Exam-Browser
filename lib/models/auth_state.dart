class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? tokenType;
  final DateTime? expiresAt;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.tokenType,
    this.expiresAt,
    this.isAuthenticated = false,
    this.error,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    String? tokenType,
    DateTime? expiresAt,
    bool? isAuthenticated,
    String? error,
    bool clearAccessToken = false,
    bool clearRefreshToken = false,
    bool clearIdToken = false,
    bool clearTokenType = false,
    bool clearExpiresAt = false,
    bool clearError = false,
  }) =>
      AuthState(
        accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
        refreshToken: clearRefreshToken ? null : (refreshToken ?? this.refreshToken),
        idToken: clearIdToken ? null : (idToken ?? this.idToken),
        tokenType: clearTokenType ? null : (tokenType ?? this.tokenType),
        expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        error: clearError ? null : (error ?? this.error),
      );
}
