class UserInfo {
  final String fullName;
  final String username;
  final int userId;
  final bool isSiteAdmin;
  final String? userPictureUrl;

  const UserInfo({
    required this.fullName,
    required this.username,
    required this.userId,
    required this.isSiteAdmin,
    this.userPictureUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      fullName: json['fullname'] as String? ?? json['username'] as String? ?? 'User',
      username: json['username'] as String? ?? '',
      userId: json['userid'] as int? ?? 0,
      isSiteAdmin: json['userissiteadmin'] as bool? ?? false,
      userPictureUrl: json['userpictureurl'] as String?,
    );
  }
}
