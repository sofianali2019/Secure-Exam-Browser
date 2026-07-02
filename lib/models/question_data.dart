import 'dart:convert';

enum QuestionType {
  multichoice,
  truefalse,
  shortanswer,
  numerical,
  matching,
  essay,
  calculated,
  calculatedmultichoice,
  ddwtos,
  gapselect,
  description,
  unknown;

  static QuestionType fromString(String s) {
    switch (s) {
      case 'multichoice':
        return QuestionType.multichoice;
      case 'truefalse':
        return QuestionType.truefalse;
      case 'shortanswer':
        return QuestionType.shortanswer;
      case 'numerical':
        return QuestionType.numerical;
      case 'matching':
        return QuestionType.matching;
      case 'essay':
        return QuestionType.essay;
      case 'calculated':
        return QuestionType.calculated;
      case 'calculatedmultichoice':
        return QuestionType.calculatedmultichoice;
      case 'ddwtos':
        return QuestionType.ddwtos;
      case 'gapselect':
        return QuestionType.gapselect;
      case 'description':
        return QuestionType.description;
      default:
        return QuestionType.unknown;
    }
  }
}

class ChoiceOption {
  final String value;
  final String text;
  final bool isCorrect;
  final double? fraction;

  const ChoiceOption({
    required this.value,
    required this.text,
    this.isCorrect = false,
    this.fraction,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
        value: json['value'] as String? ?? '',
        text: json['text'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        fraction: (json['fraction'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'text': text,
        'isCorrect': isCorrect,
        'fraction': fraction,
      };
}

class MatchingPair {
  final String questionText;
  final String? answerText;
  final int? selectedAnswerId;

  const MatchingPair({
    required this.questionText,
    this.answerText,
    this.selectedAnswerId,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) => MatchingPair(
        questionText: json['questionText'] as String? ?? '',
        answerText: json['answerText'] as String?,
        selectedAnswerId: json['selectedAnswerId'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'questionText': questionText,
        'answerText': answerText,
        'selectedAnswerId': selectedAnswerId,
      };
}

class AnswerField {
  final String name;
  final String fieldType;
  final String? value;
  final String? label;
  final bool checked;
  final int? maxlength;

  const AnswerField({
    required this.name,
    required this.fieldType,
    this.value,
    this.label,
    this.checked = false,
    this.maxlength,
  });
}

class QuestionData {
  final int slot;
  final QuestionType type;
  final String number;
  final int page;
  final int sequenceCheck;
  final bool flagged;
  final String rawHtml;
  final String questionText;
  final List<ChoiceOption> options;
  final List<MatchingPair> matchingPairs;
  final List<String> gapWords;
  final int? maxlength;
  final String? defaultValue;
  final bool singleAnswer;
  final List<AnswerField> answerFields;
  final Map<String, String> extraSettings;

  const QuestionData({
    required this.slot,
    required this.type,
    required this.number,
    required this.page,
    required this.sequenceCheck,
    this.flagged = false,
    this.rawHtml = '',
    this.questionText = '',
    this.options = const [],
    this.matchingPairs = const [],
    this.gapWords = const [],
    this.maxlength,
    this.defaultValue,
    this.singleAnswer = true,
    this.answerFields = const [],
    this.extraSettings = const {},
  });

  factory QuestionData.fromApiJson(Map<String, dynamic> json) {
    final slot = json['slot'] as int? ?? 0;
    final type = QuestionType.fromString(json['type'] as String? ?? '');
    final number = json['number'] as String? ?? '';
    final page = json['page'] as int? ?? 0;
    final sequenceCheck = json['sequencecheck'] as int? ?? 0;
    final flagged = json['flagged'] as bool? ?? false;
    final rawHtml = json['html'] as String? ?? '';
    final settingsStr = json['settings'] as String?;

    Map<String, String> extraSettings = {};
    if (settingsStr != null && settingsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(settingsStr) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          extraSettings[e.key] = e.value.toString();
        }
      } catch (_) {}
    }

    final questionText = _extractQuestionText(rawHtml);
    final (options, singleAnswer) =
        _extractOptions(rawHtml, type, extraSettings);
    final matchingPairs = _extractMatchingPairs(rawHtml, extraSettings);
    final gapWords = _extractGapWords(rawHtml, type, extraSettings);
    final maxlength = _extractMaxlength(rawHtml);
    final answerFields = _extractAnswerFields(rawHtml);

    return QuestionData(
      slot: slot,
      type: type,
      number: number,
      page: page,
      sequenceCheck: sequenceCheck,
      flagged: flagged,
      rawHtml: rawHtml,
      questionText: questionText,
      options: options,
      singleAnswer: singleAnswer,
      matchingPairs: matchingPairs,
      gapWords: gapWords,
      maxlength: maxlength,
      extraSettings: extraSettings,
      answerFields: answerFields,
    );
  }

  static String _extractQuestionText(String html) {
    final textMatch = RegExp(
      r'<div\s+class="qtext">(.*?)</div>',
      dotAll: true,
    ).firstMatch(html);
    if (textMatch != null) {
      return _stripHtml(textMatch.group(1)!);
    }
    return _stripHtml(html);
  }

  static (List<ChoiceOption>, bool) _extractOptions(
    String html,
    QuestionType type,
    Map<String, String> settings,
  ) {
    if (type == QuestionType.multichoice ||
        type == QuestionType.calculatedmultichoice) {
      final single = settings['single'] == '1' || settings['single'] == null;
      final options = <ChoiceOption>{};
      final inputMatches = RegExp(
        r'<input[^>]*type="(radio|checkbox)"[^>]*name="([^"]*)"[^>]*value="([^"]*)"[^>]*>',
        dotAll: true,
      ).allMatches(html);
      final labelMap = <String, String>{};
      final labelMatches = RegExp(
        r'<label[^>]*for="([^"]*)"[^>]*>(.*?)</label>',
        dotAll: true,
      ).allMatches(html);
      for (final m in labelMatches) {
        labelMap[m.group(1)!] = _stripHtml(m.group(2)!);
      }
      for (final m in inputMatches) {
        final value = m.group(3)!;
        final id = m.group(0)!;
        final idMatch = RegExp(r'id="([^"]*)"').firstMatch(id);
        final label = idMatch != null
            ? (labelMap[idMatch.group(1)!] ?? value)
            : value;
        options.add(ChoiceOption(value: value, text: label));
      }
      if (options.isEmpty) {
        final selectMatches = RegExp(
          r'<select[^>]*name="([^"]*)"[^>]*>(.*?)</select>',
          dotAll: true,
        ).allMatches(html);
        for (final sm in selectMatches) {
          final optMatches = RegExp(
            r'<option[^>]*value="([^"]*)"[^>]*>(.*?)</option>',
            dotAll: true,
          ).allMatches(sm.group(2)!);
          for (final om in optMatches) {
            options.add(ChoiceOption(
              value: om.group(1)!,
              text: _stripHtml(om.group(2)!),
            ));
          }
        }
      }
      if (options.isEmpty && type == QuestionType.multichoice) {
        final divClasses = RegExp(
          r'<div\s+class="r\d"[^>]*>(.*?)</div>',
          dotAll: true,
        ).allMatches(html);
        for (final dm in divClasses) {
          final inner = dm.group(1)!;
          final valueMatch = RegExp(r'value="([^"]*)"').firstMatch(inner);
          final textContent = _stripHtml(inner);
          if (valueMatch != null && textContent.isNotEmpty) {
            options.add(ChoiceOption(
              value: valueMatch.group(1)!,
              text: textContent.replaceAll(valueMatch.group(1)!, '').trim(),
            ));
          }
        }
      }
      return (options.toList(), single);
    }
    if (type == QuestionType.truefalse) {
      final options = <ChoiceOption>[];
      final inputMatches = RegExp(
        r'<input[^>]*type="radio"[^>]*name="([^"]*)"[^>]*value="([^"]*)"[^>]*>',
        dotAll: true,
      ).allMatches(html);
      final labelMap = <String, String>{};
      final labelMatches = RegExp(
        r'<label[^>]*for="([^"]*)"[^>]*>(.*?)</label>',
        dotAll: true,
      ).allMatches(html);
      for (final m in labelMatches) {
        labelMap[m.group(1)!] = _stripHtml(m.group(2)!);
      }
      for (final m in inputMatches) {
        final value = m.group(2)!;
        if (value.isNotEmpty) {
          final idMatch = RegExp(r'id="([^"]*)"').firstMatch(m.group(0)!);
          final label = idMatch != null
              ? (labelMap[idMatch.group(1)!] ?? value)
              : value;
          options.add(ChoiceOption(value: value, text: label));
        }
      }
      if (options.isEmpty) {
        options.add(const ChoiceOption(value: '1', text: 'True'));
        options.add(const ChoiceOption(value: '0', text: 'False'));
      }
      return (options, true);
    }
    return (<ChoiceOption>[], true);
  }

  static List<MatchingPair> _extractMatchingPairs(
    String html,
    Map<String, String> settings,
  ) {
    if (!html.contains('match') &&
        !html.contains('Matching') &&
        !html.contains('matching')) {
      return [];
    }
    final pairs = <MatchingPair>[];
    final questionMatches = RegExp(
      r'<div\s+class="text"[^>]*>(.*?)</div>',
      dotAll: true,
    ).allMatches(html);
    for (final m in questionMatches) {
      pairs.add(MatchingPair(questionText: _stripHtml(m.group(1)!)));
    }
    if (pairs.isEmpty) {
      final subQMatch = RegExp(
        r'<div\s+class="subquestion"[^>]*>(.*?)</div>',
        dotAll: true,
      ).allMatches(html);
      if (subQMatch.isNotEmpty) {
        for (final m in subQMatch) {
          pairs.add(MatchingPair(questionText: _stripHtml(m.group(1)!)));
        }
      }
    }
    return pairs;
  }

  static List<String> _extractGapWords(
    String html,
    QuestionType type,
    Map<String, String> settings,
  ) {
    if (type == QuestionType.gapselect) {
      final words = <String>[];
      final selectMatches = RegExp(
        r'<select[^>]*>(.*?)</select>',
        dotAll: true,
      ).allMatches(html);
      for (final sm in selectMatches) {
        final optMatches = RegExp(
          r'<option[^>]*value="([^"]*)"[^>]*>.*?</option>',
          dotAll: true,
        ).allMatches(sm.group(1)!);
        for (final om in optMatches) {
          if (om.group(1)!.isNotEmpty) {
            words.add(om.group(1)!);
          }
        }
      }
      return words;
    }
    return [];
  }

  static int? _extractMaxlength(String html) {
    final match = RegExp(r'maxlength="(\d+)"').firstMatch(html);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  static List<AnswerField> _extractAnswerFields(String html) {
    final fields = <AnswerField>[];
    final inputMatches = RegExp(
      r'<input[^>]*>',
      dotAll: true,
    ).allMatches(html);
    for (final m in inputMatches) {
      final tag = m.group(0)!;
      final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(tag);
      if (nameMatch == null) continue;
      final name = nameMatch.group(1)!;
      final typeMatch = RegExp(r'type="([^"]*)"').firstMatch(tag);
      final fieldType = typeMatch?.group(1) ?? 'text';
      final valueMatch = RegExp(r'value="([^"]*)"').firstMatch(tag);
      final checked = tag.contains('checked');
      final maxlengthMatch = RegExp(r'maxlength="(\d+)"').firstMatch(tag);
      fields.add(AnswerField(
        name: name,
        fieldType: fieldType,
        value: valueMatch?.group(1),
        checked: checked,
        maxlength: maxlengthMatch != null
            ? int.tryParse(maxlengthMatch.group(1)!)
            : null,
      ));
    }
    final selectMatches = RegExp(
      r'<select[^>]*name="([^"]*)"[^>]*>.*?</select>',
      dotAll: true,
    ).allMatches(html);
    for (final m in selectMatches) {
      final name = m.group(1)!;
      fields.add(AnswerField(
        name: name,
        fieldType: 'select',
      ));
    }
    final textareaMatches = RegExp(
      r'<textarea[^>]*name="([^"]*)"[^>]*>',
      dotAll: true,
    ).allMatches(html);
    for (final m in textareaMatches) {
      final name = m.group(1)!;
      fields.add(AnswerField(
        name: name,
        fieldType: 'textarea',
      ));
    }
    return fields;
  }

  static String _stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  List<Map<String, String>> buildSubmissionData(String? userAnswer) {
    final data = <Map<String, String>>[];
    data.add({
      'name': 'sequencecheck_$slot',
      'value': sequenceCheck.toString(),
    });
    if (type == QuestionType.multichoice ||
        type == QuestionType.calculatedmultichoice) {
      if (singleAnswer) {
        final field = answerFields.isNotEmpty
            ? answerFields.first.name
            : 'q$slot:${slot}_answer';
        data.add({
          'name': field,
          'value': userAnswer ?? '',
        });
      } else {
        for (final opt in options) {
          final selected = userAnswer?.split(',').contains(opt.value) ?? false;
          data.add({
            'name': 'q$slot:${slot}_${opt.value}',
            'value': selected ? '1' : '0',
          });
        }
      }
    } else if (type == QuestionType.truefalse) {
      final field = answerFields.isNotEmpty
          ? answerFields.first.name
          : 'q$slot:${slot}_answer';
      data.add({
        'name': field,
        'value': userAnswer ?? '',
      });
    } else if (type == QuestionType.shortanswer ||
        type == QuestionType.numerical ||
        type == QuestionType.calculated) {
      final field = answerFields.isNotEmpty
          ? answerFields.first.name
          : 'q$slot:${slot}_answer';
      data.add({
        'name': field,
        'value': userAnswer ?? '',
      });
    } else if (type == QuestionType.essay) {
      final field = answerFields.isNotEmpty
          ? answerFields.first.name
          : 'q$slot:${slot}_answer';
      data.add({
        'name': field,
        'value': userAnswer ?? '',
      });
      data.add({
        'name': '${field}:format',
        'value': '1',
      });
    } else if (type == QuestionType.matching) {
      for (final field in answerFields) {
        data.add({
          'name': field.name,
          'value': field.value ?? '0',
        });
      }
    } else if (type == QuestionType.gapselect) {
      data.add({
        'name': 'q$slot:${slot}_answer',
        'value': userAnswer ?? '',
      });
    } else {
      for (final field in answerFields) {
        data.add({
          'name': field.name,
          'value': field.value ?? '',
        });
      }
    }
    return data;
  }
}
