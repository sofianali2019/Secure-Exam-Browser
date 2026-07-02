import 'package:flutter/material.dart';
import '../../models/question_data.dart';
import 'answer_widgets.dart';

class QuestionCard extends StatelessWidget {
  final QuestionData question;
  final String currentAnswer;
  final bool isFlagged;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback onToggleFlag;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentAnswer,
    this.isFlagged = false,
    required this.onAnswerChanged,
    required this.onToggleFlag,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _typeLabel(question.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Question ${question.number}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: isFlagged ? Colors.orange : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: onToggleFlag,
                  tooltip: isFlagged ? 'Unflag' : 'Flag for review',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Question text
            Text(
              _stripHtml(question.questionText),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            // Answer widget
            _buildAnswerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget() {
    return AnswerWidget(
      question: question,
      currentAnswer: currentAnswer,
      onChanged: onAnswerChanged,
    );
  }

  String _typeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multichoice:
        return question.singleAnswer ? 'Single choice' : 'Multiple choice';
      case QuestionType.truefalse:
        return 'True / False';
      case QuestionType.shortanswer:
        return 'Short answer';
      case QuestionType.numerical:
        return 'Numerical';
      case QuestionType.matching:
        return 'Matching';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.calculated:
        return 'Calculated';
      case QuestionType.calculatedmultichoice:
        return 'Calculated multichoice';
      case QuestionType.ddwtos:
        return 'Drag & drop';
      case QuestionType.gapselect:
        return 'Select missing words';
      case QuestionType.description:
        return 'Information';
      case QuestionType.unknown:
        return question.type.name;
    }
  }
}
