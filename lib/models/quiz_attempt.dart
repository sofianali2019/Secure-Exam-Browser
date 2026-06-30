enum AttemptState { inprogress, overdue, finished, abandoned, unknown }

class QuizAttempt {
  final int id;
  final int quizId;
  final int userId;
  final int attemptNumber;
  final AttemptState state;
  final int timeStart;
  final int? timeFinish;
  final double? sumGrades;
  final double? grade;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.attemptNumber,
    this.state = AttemptState.unknown,
    this.timeStart = 0,
    this.timeFinish,
    this.sumGrades,
    this.grade,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    id: json['id'] as int,
    quizId: json['quiz'] as int,
    userId: json['userid'] as int,
    attemptNumber: json['attempt'] as int? ?? 1,
    state: _parseState(json['state'] as String?),
    timeStart: json['timestart'] as int? ?? 0,
    timeFinish: json['timefinish'] as int?,
    sumGrades: (json['sumgrades'] as num?)?.toDouble(),
    grade: (json['grade'] as num?)?.toDouble(),
  );

  static AttemptState _parseState(String? s) {
    switch (s) {
      case 'inprogress': return AttemptState.inprogress;
      case 'overdue':    return AttemptState.overdue;
      case 'finished':   return AttemptState.finished;
      case 'abandoned':  return AttemptState.abandoned;
      default:           return AttemptState.unknown;
    }
  }

  bool get isInProgress => state == AttemptState.inprogress;
  bool get isFinished => state == AttemptState.finished;

  Map<String, dynamic> toJson() => {
    'id': id,
    'quiz': quizId,
    'userid': userId,
    'attempt': attemptNumber,
    'state': state.name,
    'timestart': timeStart,
    'timefinish': timeFinish,
    'sumgrades': sumGrades,
    'grade': grade,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizAttempt && id == other.id && quizId == other.quizId;

  @override
  int get hashCode => Object.hash(id, quizId);

  @override
  String toString() =>
      'QuizAttempt(id: $id, quizId: $quizId, state: ${state.name}, attempt: $attemptNumber)';
}
