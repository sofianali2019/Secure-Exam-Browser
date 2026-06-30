class QuizInfo {
  final int id;
  final int courseId;
  final int coursemodule;
  final String name;
  final String? intro;
  final int? timeOpen;
  final int? timeClose;
  final int? timeLimit;
  final int attemptsAllowed;
  final double? gradePass;
  final double? sumGrades;
  final bool hasQuestions;
  final bool visible;

  const QuizInfo({
    required this.id,
    required this.courseId,
    required this.coursemodule,
    required this.name,
    this.intro,
    this.timeOpen,
    this.timeClose,
    this.timeLimit,
    this.attemptsAllowed = 0,
    this.gradePass,
    this.sumGrades,
    this.hasQuestions = false,
    this.visible = true,
  });

  factory QuizInfo.fromJson(Map<String, dynamic> json) => QuizInfo(
    id: json['id'] as int,
    courseId: json['course'] as int,
    coursemodule: json['coursemodule'] as int,
    name: json['name'] as String? ?? '',
    intro: json['intro'] as String?,
    timeOpen: json['timeopen'] as int?,
    timeClose: json['timeclose'] as int?,
    timeLimit: json['timelimit'] as int?,
    attemptsAllowed: json['attempts'] as int? ?? 0,
    gradePass: (json['gradepass'] as num?)?.toDouble(),
    sumGrades: (json['sumgrades'] as num?)?.toDouble(),
    hasQuestions: (json['hasquestions'] is bool)
        ? (json['hasquestions'] as bool)
        : (json['hasquestions'] as num?)?.toInt() == 1,
    visible: json['visible'] as bool? ?? true,
  );

  String viewUrl(String baseUrl) =>
    '$baseUrl/mod/quiz/view.php?id=$coursemodule';

  bool get isAvailable {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (timeOpen != null && timeOpen! > 0 && now < timeOpen!) return false;
    if (timeClose != null && timeClose! > 0 && now > timeClose!) return false;
    return true;
  }

  String get timeLimitFormatted {
    if (timeLimit == null || timeLimit == 0) return 'No limit';
    final minutes = timeLimit! ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizInfo && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'QuizInfo(id: $id, name: $name, courseId: $courseId)';
}
