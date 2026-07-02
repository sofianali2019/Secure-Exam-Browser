import 'package:flutter/material.dart';
import '../../models/question_data.dart';

class AnswerWidget extends StatelessWidget {
  final QuestionData question;
  final String currentAnswer;
  final ValueChanged<String> onChanged;

  const AnswerWidget({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multichoice:
      case QuestionType.calculatedmultichoice:
        return MultichoiceAnswer(
          options: question.options,
          single: question.singleAnswer,
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.truefalse:
        return TrueFalseAnswer(
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.shortanswer:
        return ShortAnswerField(
          value: currentAnswer,
          maxLength: question.maxlength,
          onChanged: onChanged,
        );
      case QuestionType.numerical:
      case QuestionType.calculated:
        return NumericalField(
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.matching:
        return MatchingAnswer(
          pairs: question.matchingPairs,
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.essay:
        return EssayField(
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.gapselect:
        return GapSelectAnswer(
          question: question,
          value: currentAnswer,
          onChanged: onChanged,
        );
      case QuestionType.ddwtos:
      case QuestionType.description:
      case QuestionType.unknown:
        return _FallbackAnswer(
          value: currentAnswer,
          onChanged: onChanged,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Multiple choice (single = radio, multi = checkbox)
// ---------------------------------------------------------------------------
class MultichoiceAnswer extends StatelessWidget {
  final List<ChoiceOption> options;
  final bool single;
  final String value;
  final ValueChanged<String> onChanged;

  const MultichoiceAnswer({
    super.key,
    required this.options,
    required this.single,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const Text('No options available',
          style: TextStyle(color: Colors.grey));
    }

    if (single) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          final selected = value == opt.value;
          return RadioListTile<String>(
            title: Text(opt.text, style: const TextStyle(fontSize: 15)),
            value: opt.value,
            groupValue: value.isEmpty ? null : value,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            selected: selected,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            dense: true,
          );
        }).toList(),
      );
    }

    // Multiple answers
    final selectedValues = value.isEmpty ? <String>{} : value.split(',').toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((opt) {
        final checked = selectedValues.contains(opt.value);
        return CheckboxListTile(
          title: Text(opt.text, style: const TextStyle(fontSize: 15)),
          value: checked,
          onChanged: (_) {
            final updated = <String>{...selectedValues};
            if (checked) {
              updated.remove(opt.value);
            } else {
              updated.add(opt.value);
            }
            onChanged(updated.join(','));
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// True / False
// ---------------------------------------------------------------------------
class TrueFalseAnswer extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TrueFalseAnswer({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TfButton(label: 'True', value: '1', selectedValue: value, onChanged: onChanged),
        const SizedBox(width: 12),
        _TfButton(label: 'False', value: '0', selectedValue: value, onChanged: onChanged),
      ],
    );
  }
}

class _TfButton extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _TfButton({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedValue == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onChanged(value),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Short answer
// ---------------------------------------------------------------------------
class ShortAnswerField extends StatelessWidget {
  final String value;
  final int? maxLength;
  final ValueChanged<String> onChanged;

  const ShortAnswerField({
    super.key,
    required this.value,
    this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      maxLength: maxLength,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
    );
  }
}

// ---------------------------------------------------------------------------
// Numerical
// ---------------------------------------------------------------------------
class NumericalField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const NumericalField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        hintText: 'Enter a number...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
        prefixIcon: const Icon(Icons.calculate_outlined, size: 20),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
    );
  }
}

// ---------------------------------------------------------------------------
// Matching
// ---------------------------------------------------------------------------
class MatchingAnswer extends StatefulWidget {
  final List<MatchingPair> pairs;
  final String value;
  final ValueChanged<String> onChanged;

  const MatchingAnswer({
    super.key,
    required this.pairs,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MatchingAnswer> createState() => _MatchingAnswerState();
}

class _MatchingAnswerState extends State<MatchingAnswer> {
  final Map<int, String> _selections = {};

  @override
  void initState() {
    super.initState();
    if (widget.value.isNotEmpty) {
      final parts = widget.value.split(',');
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          _selections[int.tryParse(kv[0]) ?? 0] = kv[1];
        }
      }
    }
  }

  void _update(int index, String answerId) {
    _selections[index] = answerId;
    final encoded =
        _selections.entries.map((e) => '${e.key}:${e.value}').join(',');
    widget.onChanged(encoded);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pairs.isEmpty) {
      return const Text('Matching question (pairs not parsed)',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: widget.pairs.asMap().entries.map((entry) {
        final i = entry.key;
        final pair = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(pair.questionText,
                    style: const TextStyle(fontSize: 14)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              ),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selections[i],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  hint: const Text('Choose', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem(
                      value: '0',
                      child: Text('--', style: TextStyle(fontSize: 13)),
                    ),
                    for (var j = 0; j < widget.pairs.length; j++)
                      DropdownMenuItem(
                        value: '${j + 1}',
                        child: Text('Option ${j + 1}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) _update(i, v);
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Essay
// ---------------------------------------------------------------------------
class EssayField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const EssayField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        hintText: 'Write your answer...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(14),
        alignLabelWithHint: true,
      ),
      maxLines: 6,
      onChanged: onChanged,
      textInputAction: TextInputAction.newline,
    );
  }
}

// ---------------------------------------------------------------------------
// Gap select (select missing words)
// ---------------------------------------------------------------------------
class GapSelectAnswer extends StatelessWidget {
  final QuestionData question;
  final String value;
  final ValueChanged<String> onChanged;

  const GapSelectAnswer({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the correct words:',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.gapWords.map((word) {
            final selected = value == word;
            return FilterChip(
              label: Text(word),
              selected: selected,
              onSelected: (_) => onChanged(selected ? '' : word),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback for unsupported types
// ---------------------------------------------------------------------------
class _FallbackAnswer extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FallbackAnswer({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Text(
            'This question type is displayed in simplified mode.',
            style: TextStyle(fontSize: 12, color: Colors.amber),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
          maxLines: 3,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
