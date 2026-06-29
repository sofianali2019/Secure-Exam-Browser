class ExamConfig {
  final String moodleUrl;
  final int examDurationMinutes;
  final bool proctoringEnabled;
  final int proctoringIntervalSeconds;
  final bool blockScreenshots;
  final bool blockAppSwitching;
  final bool blockNotifications;
  final bool blockKeyboardShortcuts;
  final bool blockRightClick;
  final bool fullscreenOnly;
  final List<String> allowedDomains;
  final String? configKey;
  final String? examTitle;

  const ExamConfig({
    required this.moodleUrl,
    this.examDurationMinutes = 60,
    this.proctoringEnabled = false,
    this.proctoringIntervalSeconds = 30,
    this.blockScreenshots = true,
    this.blockAppSwitching = true,
    this.blockNotifications = true,
    this.blockKeyboardShortcuts = true,
    this.blockRightClick = true,
    this.fullscreenOnly = true,
    this.allowedDomains = const [],
    this.configKey,
    this.examTitle,
  });

  List<String> get effectiveAllowedDomains {
    if (allowedDomains.isNotEmpty) return allowedDomains;
    final uri = Uri.tryParse(moodleUrl);
    if (uri != null && uri.host.isNotEmpty) return [uri.host];
    return [];
  }

  Map<String, dynamic> toJson() => {
        'moodleUrl': moodleUrl,
        'examDurationMinutes': examDurationMinutes,
        'proctoringEnabled': proctoringEnabled,
        'proctoringIntervalSeconds': proctoringIntervalSeconds,
        'blockScreenshots': blockScreenshots,
        'blockAppSwitching': blockAppSwitching,
        'blockNotifications': blockNotifications,
        'blockKeyboardShortcuts': blockKeyboardShortcuts,
        'blockRightClick': blockRightClick,
        'fullscreenOnly': fullscreenOnly,
        'allowedDomains': allowedDomains,
        'configKey': configKey,
        'examTitle': examTitle,
      };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
        moodleUrl: json['moodleUrl'] as String,
        examDurationMinutes: json['examDurationMinutes'] as int? ?? 60,
        proctoringEnabled: json['proctoringEnabled'] as bool? ?? false,
        proctoringIntervalSeconds:
            json['proctoringIntervalSeconds'] as int? ?? 30,
        blockScreenshots: json['blockScreenshots'] as bool? ?? true,
        blockAppSwitching: json['blockAppSwitching'] as bool? ?? true,
        blockNotifications: json['blockNotifications'] as bool? ?? true,
        blockKeyboardShortcuts:
            json['blockKeyboardShortcuts'] as bool? ?? true,
        blockRightClick: json['blockRightClick'] as bool? ?? true,
        fullscreenOnly: json['fullscreenOnly'] as bool? ?? true,
        allowedDomains:
            (json['allowedDomains'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
        configKey: json['configKey'] as String?,
        examTitle: json['examTitle'] as String?,
      );
}
