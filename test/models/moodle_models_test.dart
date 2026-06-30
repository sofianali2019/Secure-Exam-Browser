import 'package:flutter_test/flutter_test.dart';
import 'package:secure_exam_browser/models/course_info.dart';
import 'package:secure_exam_browser/models/quiz_attempt.dart';
import 'package:secure_exam_browser/models/quiz_info.dart';

void main() {
  group('CourseInfo', () {
    test('fromJson creates correct object from full data', () {
      final json = {
        'id': 3,
        'fullname': 'Mathematics 101',
        'shortname': 'MAT101',
        'displayname': 'Mathematics 101',
        'summary': '<p>Introduction to Algebra</p>',
        'startdate': 1704067200,
        'enddate': 1711843200,
        'coursecategory': 'Science',
        'progress': 60,
        'isfavourite': true,
        'hidden': false,
        'timeaccess': 1712345678,
        'courseimage': 'https://example.com/math.jpg',
      };

      final course = CourseInfo.fromJson(json);

      expect(course.id, 3);
      expect(course.fullName, 'Mathematics 101');
      expect(course.shortName, 'MAT101');
      expect(course.displayName, 'Mathematics 101');
      expect(course.summary, '<p>Introduction to Algebra</p>');
      expect(course.startDate, 1704067200);
      expect(course.endDate, 1711843200);
      expect(course.courseCategory, 'Science');
      expect(course.progress, 60);
      expect(course.isFavourite, isTrue);
      expect(course.hidden, isFalse);
      expect(course.timeaccess, 1712345678);
      expect(course.courseImageUrl, 'https://example.com/math.jpg');
    });

    test('fromJson uses defaults when fields are missing', () {
      final json = <String, dynamic>{
        'id': 5,
        'fullname': 'Physics 101',
      };

      final course = CourseInfo.fromJson(json);

      expect(course.id, 5);
      expect(course.fullName, 'Physics 101');
      expect(course.shortName, '');
      expect(course.displayName, '');
      expect(course.summary, '');
      expect(course.startDate, isNull);
      expect(course.endDate, isNull);
      expect(course.courseCategory, isNull);
      expect(course.progress, isNull);
      expect(course.isFavourite, isFalse);
      expect(course.hidden, isFalse);
      expect(course.timeaccess, isNull);
      expect(course.courseImageUrl, isNull);
    });

    test('fromJson handles nullable fields set to null', () {
      final json = {
        'id': 7,
        'fullname': 'Chemistry 101',
        'shortname': 'CHM101',
        'displayname': 'Chemistry 101',
        'summary': '<p>Basic Chemistry</p>',
        'startdate': null,
        'enddate': null,
        'coursecategory': null,
        'progress': null,
        'isfavourite': false,
        'hidden': false,
        'timeaccess': null,
        'courseimage': null,
      };

      final course = CourseInfo.fromJson(json);

      expect(course.id, 7);
      expect(course.fullName, 'Chemistry 101');
      expect(course.shortName, 'CHM101');
      expect(course.startDate, isNull);
      expect(course.endDate, isNull);
      expect(course.courseCategory, isNull);
      expect(course.progress, isNull);
      expect(course.timeaccess, isNull);
      expect(course.courseImageUrl, isNull);
    });

    test('toJson and fromJson round-trip preserves all fields', () {
      const original = CourseInfo(
        id: 10,
        fullName: 'Data Structures',
        shortName: 'DS201',
        displayName: 'Data Structures 201',
        summary: 'Course on data structures.',
        startDate: 1704067200,
        endDate: 1711843200,
        courseCategory: 'Computer Science',
        progress: 75,
        isFavourite: true,
        hidden: false,
        timeaccess: 1712345678,
        courseImageUrl: 'https://example.com/ds.jpg',
      );

      final json = original.toJson();
      final restored = CourseInfo.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.shortName, original.shortName);
      expect(restored.displayName, original.displayName);
      expect(restored.summary, original.summary);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.courseCategory, original.courseCategory);
      expect(restored.progress, original.progress);
      expect(restored.isFavourite, original.isFavourite);
      expect(restored.hidden, original.hidden);
      expect(restored.timeaccess, original.timeaccess);
      expect(restored.courseImageUrl, original.courseImageUrl);
    });

    test('equality compares id and fullName', () {
      const a = CourseInfo(id: 1, fullName: 'Math');
      const b = CourseInfo(id: 1, fullName: 'Math');
      const c = CourseInfo(id: 2, fullName: 'Physics');

      expect(a, equals(b));
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('QuizInfo', () {
    test('fromJson creates correct object from full data', () {
      final json = {
        'id': 42,
        'course': 3,
        'coursemodule': 123,
        'name': 'Midterm Exam',
        'intro': '<p>Chapters 1-6</p>',
        'timeopen': 1704153600,
        'timeclose': 1704240000,
        'timelimit': 3600,
        'attempts': 1,
        'gradepass': 60.0,
        'sumgrades': 100.0,
        'hasquestions': true,
        'visible': true,
      };

      final quiz = QuizInfo.fromJson(json);

      expect(quiz.id, 42);
      expect(quiz.courseId, 3);
      expect(quiz.coursemodule, 123);
      expect(quiz.name, 'Midterm Exam');
      expect(quiz.intro, '<p>Chapters 1-6</p>');
      expect(quiz.timeOpen, 1704153600);
      expect(quiz.timeClose, 1704240000);
      expect(quiz.timeLimit, 3600);
      expect(quiz.attemptsAllowed, 1);
      expect(quiz.gradePass, 60.0);
      expect(quiz.sumGrades, 100.0);
      expect(quiz.hasQuestions, isTrue);
      expect(quiz.visible, isTrue);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = <String, dynamic>{
        'id': 11,
        'course': 2,
        'coursemodule': 456,
        'name': 'Quick Quiz',
      };

      final quiz = QuizInfo.fromJson(json);

      expect(quiz.id, 11);
      expect(quiz.courseId, 2);
      expect(quiz.coursemodule, 456);
      expect(quiz.name, 'Quick Quiz');
      expect(quiz.intro, isNull);
      expect(quiz.timeOpen, isNull);
      expect(quiz.timeClose, isNull);
      expect(quiz.timeLimit, isNull);
      expect(quiz.attemptsAllowed, 0);
      expect(quiz.gradePass, isNull);
      expect(quiz.sumGrades, isNull);
      expect(quiz.hasQuestions, isFalse);
      expect(quiz.visible, isTrue);
    });

    test('fromJson handles nullable fields set to null', () {
      final json = {
        'id': 13,
        'course': 3,
        'coursemodule': 789,
        'name': 'Quiz with Nulls',
        'intro': null,
        'timeopen': null,
        'timeclose': null,
        'timelimit': null,
        'attempts': null,
        'gradepass': null,
        'sumgrades': null,
        'hasquestions': false,
        'visible': true,
      };

      final quiz = QuizInfo.fromJson(json);

      expect(quiz.intro, isNull);
      expect(quiz.timeOpen, isNull);
      expect(quiz.timeClose, isNull);
      expect(quiz.timeLimit, isNull);
      expect(quiz.attemptsAllowed, 0);
      expect(quiz.gradePass, isNull);
      expect(quiz.sumGrades, isNull);
      expect(quiz.hasQuestions, isFalse);
    });

    test('timeLimitFormatted returns correct human-readable strings', () {
      final noLimit = QuizInfo(id: 1, courseId: 1, coursemodule: 1, name: 'q');
      expect(noLimit.timeLimitFormatted, 'No limit');

      final nullLimit = QuizInfo(
          id: 2, courseId: 1, coursemodule: 1, name: 'q', timeLimit: null);
      expect(nullLimit.timeLimitFormatted, 'No limit');

      final justMinutes =
          QuizInfo(id: 3, courseId: 1, coursemodule: 1, name: 'q', timeLimit: 1800);
      expect(justMinutes.timeLimitFormatted, '30 min');

      final justHours =
          QuizInfo(id: 4, courseId: 1, coursemodule: 1, name: 'q', timeLimit: 7200);
      expect(justHours.timeLimitFormatted, '2h');

      final hoursAndMinutes =
          QuizInfo(id: 5, courseId: 1, coursemodule: 1, name: 'q', timeLimit: 5400);
      expect(hoursAndMinutes.timeLimitFormatted, '1h 30m');
    });

    test('isAvailable checks timeOpen and timeClose', () {
      final farFuture = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 86400;
      final farPast = 1000000;

      final notYetOpen = QuizInfo(
        id: 1, courseId: 1, coursemodule: 1, name: 'q',
        timeOpen: farFuture,
      );
      expect(notYetOpen.isAvailable, isFalse);

      const alreadyClosed = QuizInfo(
        id: 2, courseId: 1, coursemodule: 1, name: 'q',
        timeClose: 1, // epoch is long past
      );
      expect(alreadyClosed.isAvailable, isFalse);

      final noRestrictions = QuizInfo(
        id: 3, courseId: 1, coursemodule: 1, name: 'q',
        timeOpen: farPast,
        timeClose: farFuture,
      );
      expect(noRestrictions.isAvailable, isTrue);
    });
  });

  group('QuizAttempt', () {
    test('fromJson creates correct object from full data', () {
      final json = {
        'id': 100,
        'quiz': 10,
        'userid': 42,
        'attempt': 1,
        'state': 'inprogress',
        'timestart': 1719676800,
        'timefinish': null,
        'sumgrades': null,
        'grade': null,
      };

      final attempt = QuizAttempt.fromJson(json);

      expect(attempt.id, 100);
      expect(attempt.quizId, 10);
      expect(attempt.userId, 42);
      expect(attempt.attemptNumber, 1);
      expect(attempt.state, AttemptState.inprogress);
      expect(attempt.timeStart, 1719676800);
      expect(attempt.timeFinish, isNull);
      expect(attempt.sumGrades, isNull);
      expect(attempt.grade, isNull);
      expect(attempt.isInProgress, isTrue);
      expect(attempt.isFinished, isFalse);
    });

    test('fromJson handles finished attempt with grades', () {
      final json = {
        'id': 987,
        'quiz': 42,
        'userid': 5,
        'attempt': 1,
        'state': 'finished',
        'timestart': 1704154000,
        'timefinish': 1704157000,
        'sumgrades': 85.5,
        'grade': 90.0,
      };

      final attempt = QuizAttempt.fromJson(json);

      expect(attempt.state, AttemptState.finished);
      expect(attempt.timeFinish, 1704157000);
      expect(attempt.sumGrades, 85.5);
      expect(attempt.grade, 90.0);
      expect(attempt.isFinished, isTrue);
      expect(attempt.isInProgress, isFalse);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{
        'id': 102,
        'quiz': 12,
        'userid': 99,
      };

      final attempt = QuizAttempt.fromJson(json);

      expect(attempt.id, 102);
      expect(attempt.quizId, 12);
      expect(attempt.userId, 99);
      expect(attempt.attemptNumber, 1);
      expect(attempt.state, AttemptState.unknown);
      expect(attempt.timeStart, 0);
      expect(attempt.timeFinish, isNull);
      expect(attempt.sumGrades, isNull);
      expect(attempt.grade, isNull);
    });

    test('fromJson correctly maps state strings to AttemptState enum', () {
      final cases = {
        'inprogress': AttemptState.inprogress,
        'overdue': AttemptState.overdue,
        'finished': AttemptState.finished,
        'abandoned': AttemptState.abandoned,
        'unrecognised': AttemptState.unknown,
        null: AttemptState.unknown,
      };

      for (final entry in cases.entries) {
        final json = <String, dynamic>{
          'id': 1,
          'quiz': 1,
          'userid': 1,
          'attempt': 1,
          'state': entry.key,
          'timestart': 1000,
        };
        final attempt = QuizAttempt.fromJson(json);
        expect(attempt.state, entry.value,
            reason: 'state "${entry.key}" should map to ${entry.value}');
      }
    });

    test('toJson and fromJson round-trip preserves all fields', () {
      const original = QuizAttempt(
        id: 200,
        quizId: 15,
        userId: 100,
        attemptNumber: 2,
        state: AttemptState.finished,
        timeStart: 1719676800,
        timeFinish: 1719680400,
        sumGrades: 92.5,
        grade: 95.0,
      );

      final json = original.toJson();
      final restored = QuizAttempt.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.quizId, original.quizId);
      expect(restored.userId, original.userId);
      expect(restored.attemptNumber, original.attemptNumber);
      expect(restored.state, original.state);
      expect(restored.timeStart, original.timeStart);
      expect(restored.timeFinish, original.timeFinish);
      expect(restored.sumGrades, original.sumGrades);
      expect(restored.grade, original.grade);
    });
  });
}
