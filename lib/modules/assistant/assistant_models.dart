import 'package:flutter/material.dart';

/// Who sent a chat message.
enum Sender { user, assistant }

/// The kinds of small chart an assistant answer can embed in its bubble.
enum AnswerChartKind { bars, line, donut }

/// A headline number inside an answer.
class AnswerKpi {
  const AnswerKpi({required this.label, required this.value, this.icon, this.spark = const []});
  final String label;
  final String value;
  final IconData? icon;
  final List<double> spark;
}

/// A small table inside an answer bubble (scrolls horizontally, never widens
/// the bubble).
class AnswerTable {
  const AnswerTable({required this.columns, required this.numeric, required this.rows});
  final List<String> columns;

  /// Per-column: is this an end-aligned numeric column?
  final List<bool> numeric;
  final List<List<String>> rows;
}

/// A small chart inside an answer bubble.
class AnswerChart {
  const AnswerChart({
    required this.kind,
    required this.labels,
    required this.values,
    this.unit,
  });
  final AnswerChartKind kind;
  final List<String> labels;
  final List<double> values;
  final String? unit;

  bool get hasData => values.any((v) => v != 0);
}

/// A rich assistant answer: leading text plus any of KPIs / table / chart.
class AssistantAnswer {
  const AssistantAnswer({
    required this.text,
    this.kpis = const [],
    this.table,
    this.chart,
  });
  final String text;
  final List<AnswerKpi> kpis;
  final AnswerTable? table;
  final AnswerChart? chart;

  /// True when the answer references a chart or table that can move to the side
  /// panel on a wide screen.
  bool get hasReference => chart != null || table != null;
}

/// One message in the conversation.
class ChatMessage {
  const ChatMessage._({required this.sender, this.text, this.answer, this.typing = false});

  const ChatMessage.user(String text) : this._(sender: Sender.user, text: text);
  const ChatMessage.assistant(AssistantAnswer answer)
      : this._(sender: Sender.assistant, answer: answer);
  const ChatMessage.typing() : this._(sender: Sender.assistant, typing: true);

  final Sender sender;
  final String? text;
  final AssistantAnswer? answer;
  final bool typing;
}

/// A tappable suggested question.
class SuggestedQuestion {
  const SuggestedQuestion({required this.id, required this.text, required this.icon});
  final String id;
  final String text;
  final IconData icon;
}
