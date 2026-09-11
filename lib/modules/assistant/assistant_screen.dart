import 'package:flutter/material.dart';

import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_table.dart';
import 'assistant_charts.dart';
import 'assistant_models.dart';
import 'assistant_responder.dart';

/// The AI assistant — a chat where a business owner asks about their data and
/// gets a rich answer (text · KPIs · table · chart).
///
/// Structure: `Column = [header] + [Expanded list] + [chips] + [input]`, no
/// fixed heights. The conversation is always centred and width-capped (a
/// screen-wide chat is unreadable). The composer is pinned to the bottom,
/// respects the keyboard inset and SafeArea, and the list auto-scrolls to the
/// newest message when a message arrives or the keyboard opens. In the
/// landscape-phone-with-keyboard worst case the header condenses, the
/// suggestion chips hide and the composer caps at two lines so the input and
/// last message stay visible.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.testInitialQuestionId, this.testConnectionError = false});

  /// Test/demo hook: seed one question + its answer so a rich conversation is
  /// visible immediately.
  final String? testInitialQuestionId;

  /// Test/demo hook: start in the connection-error state.
  final bool testConnectionError;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> with WidgetsBindingObserver {
  final _messages = <ChatMessage>[];
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _atBottom = true;
  bool _seeded = false;
  late bool _connectionError = widget.testConnectionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      _atBottom = _scroll.offset >= _scroll.position.maxScrollExtent - 60;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  DemoStore get _store => DemoStoreProvider.of(context);

  @override
  void didChangeMetrics() {
    // Keyboard open/close or rotation: keep pinned to the bottom if we were
    // already there; otherwise preserve the reading position (never jump up).
    if (_atBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
    _atBottom = true;
  }

  void _seedIfNeeded() {
    if (_seeded) return;
    _seeded = true;
    final id = widget.testInitialQuestionId;
    if (id == null) return;
    final q = suggestedQuestions.firstWhere((x) => x.id == id,
        orElse: () => SuggestedQuestion(id: id, text: id, icon: Icons.chat_bubble_outline_rounded));
    _messages
      ..add(ChatMessage.user(q.text))
      ..add(ChatMessage.assistant(answerFor(_store, id)));
  }

  void _send(String id, String display) {
    final text = display.trim();
    if (text.isEmpty) return;
    setState(() {
      _connectionError = false;
      _messages
        ..add(ChatMessage.user(text))
        ..add(const ChatMessage.typing());
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: true));
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty && _messages.last.typing) {
          _messages.removeLast();
        }
        _messages.add(ChatMessage.assistant(answerFor(_store, id)));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: true));
    });
  }

  void _sendTyped() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _send(t, t); // free text → responder falls back
  }

  AnswerChart? _latestChart() {
    for (final m in _messages.reversed) {
      final ch = m.answer?.chart;
      if (ch != null && ch.hasData) return ch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        _seedIfNeeded();
        final taj = context.taj;
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final compact = h <= AppBreakpoints.chatCompactHeight;

                final latestChart = _latestChart();
                final showPanel = w >= AppBreakpoints.assistantSidePanel && latestChart != null;

                final convCap = showPanel
                    ? AppBreakpoints.chatMaxWidth
                    : (w < AppBreakpoints.phone
                        ? w
                        : (w < AppBreakpoints.tablet
                            ? AppBreakpoints.chatWidthTablet
                            : AppBreakpoints.chatMaxWidth));

                final conversation = _Conversation(
                  messages: _messages,
                  scroll: _scroll,
                  input: _input,
                  focus: _focus,
                  convCap: convCap,
                  compact: compact,
                  suppressChart: showPanel,
                  connectionError: _connectionError,
                  onSend: _send,
                  onSubmit: _sendTyped,
                  onRetry: () => setState(() => _connectionError = false),
                );

                if (showPanel) {
                  final panelW = (w * 0.30)
                      .clamp(AppBreakpoints.assistantPanelMin, AppBreakpoints.assistantPanelMax)
                      .toDouble();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: conversation),
                      VerticalDivider(width: 1, color: taj.divider),
                      SizedBox(width: panelW, child: _ReferencePanel(chart: latestChart)),
                    ],
                  );
                }
                return conversation;
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation column
// ---------------------------------------------------------------------------

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.messages,
    required this.scroll,
    required this.input,
    required this.focus,
    required this.convCap,
    required this.compact,
    required this.suppressChart,
    required this.connectionError,
    required this.onSend,
    required this.onSubmit,
    required this.onRetry,
  });

  final List<ChatMessage> messages;
  final ScrollController scroll;
  final TextEditingController input;
  final FocusNode focus;
  final double convCap;
  final bool compact;
  final bool suppressChart;
  final bool connectionError;
  final void Function(String id, String display) onSend;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  double get _bubbleMax =>
      (convCap * AppBreakpoints.chatBubbleWidthFactor).clamp(160.0, AppBreakpoints.chatBubbleMaxWidth);

  @override
  Widget build(BuildContext context) {
    final empty = messages.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(compact: compact),
        Expanded(
          child: empty && !connectionError
              ? _EmptyState(convCap: convCap, onSend: onSend)
              : _MessageList(
                  messages: messages,
                  scroll: scroll,
                  convCap: convCap,
                  bubbleMax: _bubbleMax,
                  suppressChart: suppressChart,
                ),
        ),
        if (connectionError) _ErrorBanner(convCap: convCap, onRetry: onRetry),
        if (!compact && !empty)
          _SuggestionChips(convCap: convCap, onSend: onSend),
        _Composer(
          input: input,
          focus: focus,
          convCap: convCap,
          compact: compact,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, compact ? 6 : 12),
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 36,
            height: compact ? 30 : 36,
            decoration: BoxDecoration(color: taj.primary.lighter, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.auto_awesome_rounded, size: compact ? 17 : 20, color: taj.primary.dark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المساعد الذكي',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (!compact)
                  Text('اسأل عن مبيعاتك ومصروفاتك ومخزونك',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message list + bubbles
// ---------------------------------------------------------------------------

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scroll,
    required this.convCap,
    required this.bubbleMax,
    required this.suppressChart,
  });

  final List<ChatMessage> messages;
  final ScrollController scroll;
  final double convCap;
  final double bubbleMax;
  final bool suppressChart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: convCap),
        child: ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: messages.length,
          itemBuilder: (context, i) => _Bubble(
            message: messages[i],
            bubbleMax: bubbleMax,
            suppressChart: suppressChart,
          ),
        ),
      ),
    );
  }
}

/// Inserts zero-width spaces into very long unbroken tokens (reference codes,
/// URLs) so they can wrap instead of stretching/overflowing the bubble.
String _breakable(String s) => s.split(' ').map((w) {
      if (w.length < 20) return w;
      final b = StringBuffer();
      for (var i = 0; i < w.length; i++) {
        b.write(w[i]);
        if ((i + 1) % 12 == 0) b.write('​');
      }
      return b.toString();
    }).join(' ');

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.bubbleMax, required this.suppressChart});
  final ChatMessage message;
  final double bubbleMax;
  final bool suppressChart;

  @override
  Widget build(BuildContext context) {
    if (message.typing) return const _TypingBubble();
    final isUser = message.sender == Sender.user;
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final content = <Widget>[];
    if (isUser) {
      content.add(Text(_breakable(message.text ?? ''),
          style: text.bodyMedium?.copyWith(color: taj.primary.contrastText, height: 1.5)));
    } else {
      final a = message.answer!;
      content.add(Text(_breakable(a.text), style: text.bodyMedium?.copyWith(height: 1.5)));
      if (a.kpis.isNotEmpty) {
        content
          ..add(const SizedBox(height: 10))
          ..add(_KpiWrap(kpis: a.kpis));
      }
      if (a.table != null) {
        content
          ..add(const SizedBox(height: 10))
          ..add(_TableView(table: a.table!));
      }
      if (a.chart != null) {
        if (suppressChart) {
          content
            ..add(const SizedBox(height: 8))
            ..add(_PanelHint());
        } else {
          content
            ..add(const SizedBox(height: 10))
            ..add(AnswerChartView(chart: a.chart!));
        }
      }
    }

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: bubbleMax),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? taj.primary.main : taj.paper,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isUser ? 14 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 14),
        ),
        border: isUser ? null : Border.all(color: taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: content,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: bubble,
      ),
    );
  }
}

/// A three-dot typing indicator with a reserved fixed height so it never causes
/// the list to jump when it appears/disappears.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(14),
            ),
            border: Border.all(color: taj.divider),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: taj.textDisabled, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiWrap extends StatelessWidget {
  const _KpiWrap({required this.kpis});
  final List<AnswerKpi> kpis;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in kpis)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (k.icon != null) ...[Icon(k.icon, size: 13, color: taj.textSecondary), const SizedBox(width: 4)],
                    Flexible(child: Text(k.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: taj.textSecondary))),
                  ]),
                  const SizedBox(height: 3),
                  Text(k.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppThemes.numeralStyle(context, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.table});
  final AnswerTable table;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TajTable(
      columns: [
        for (var i = 0; i < table.columns.length; i++)
          TajColumn(table.columns[i], numeric: i < table.numeric.length && table.numeric[i]),
      ],
      rows: [
        for (final r in table.rows)
          TajRowData(cells: [
            for (var i = 0; i < r.length; i++)
              i < table.numeric.length && table.numeric[i]
                  ? Text(r[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppThemes.numeralStyle(context, fontSize: 13, fontWeight: FontWeight.w600))
                  : Text(r[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          ]),
      ],
    );
  }
}

class _PanelHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: taj.info.lighter, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, size: 15, color: taj.info.dark),
          const SizedBox(width: 6),
          Flexible(
            child: Text('الرسم معروض في اللوحة الجانبية',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: taj.info.dark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state, chips, composer, error banner, reference panel
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.convCap, required this.onSend});
  final double convCap;
  final void Function(String id, String display) onSend;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        // Vertically centred when tall, but still scrollable at 430px height.
        final pad = pagePaddingForWidth(c.maxWidth);
        final gridW = (c.maxWidth - pad * 2).clamp(0.0, convCap);
        final cols = gridColumnsFor(gridW, minItemWidth: AppBreakpoints.chatSuggestionCardMin, maxColumns: 3);
        const spacing = 12.0;
        final cellW = (gridW - spacing * (cols - 1)) / cols;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: convCap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: taj.primary.lighter, shape: BoxShape.circle),
                        child: Icon(Icons.auto_awesome_rounded, size: 30, color: taj.primary.dark),
                      ),
                      const SizedBox(height: 16),
                      Text('كيف يمكنني مساعدتك؟', textAlign: TextAlign.center, style: text.titleMedium),
                      const SizedBox(height: 6),
                      Text('اختر سؤالًا للبدء، أو اكتب سؤالك في الأسفل.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final q in suggestedQuestions)
                            SizedBox(
                              width: cellW,
                              child: _SuggestionCard(q: q, onTap: () => onSend(q.id, q.text)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.q, required this.onTap});
  final SuggestedQuestion q;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            children: [
              Icon(q.icon, size: 18, color: taj.primary.dark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(q.text,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.convCap, required this.onSend});
  final double convCap;
  final void Function(String id, String display) onSend;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      decoration: BoxDecoration(color: taj.background, border: Border(top: BorderSide(color: taj.divider))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: convCap),
          child: LayoutBuilder(
            builder: (context, c) {
              final chips = [
                for (final q in suggestedQuestions)
                  _Chip(label: q.text, icon: q.icon, onTap: () => onSend(q.id, q.text)),
              ];
              // Wrap when there is room; a horizontally scrollable row when narrow.
              if (c.maxWidth >= AppBreakpoints.phone) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  for (final ch in chips) Padding(padding: const EdgeInsets.only(left: 8), child: ch),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: taj.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.input,
    required this.focus,
    required this.convCap,
    required this.compact,
    required this.onSubmit,
  });
  final TextEditingController input;
  final FocusNode focus;
  final double convCap;
  final bool compact;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    // Belt-and-suspenders: the resizing Scaffold already lifts the body above
    // the keyboard, but adding the inset keeps the composer clear even if a
    // host disables that.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: BoxDecoration(color: taj.paper, border: Border(top: BorderSide(color: taj.divider))),
      padding: EdgeInsets.only(bottom: inset),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: convCap),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundIconButton(
                  icon: Icons.attach_file_rounded,
                  tooltip: 'إرفاق',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الإرفاق قريبًا')),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ConstrainedBox(
                    // Grows with the text up to the line cap, then scrolls
                    // internally — never pushing the buttons out of the row.
                    constraints: const BoxConstraints(minHeight: 44),
                    child: TextField(
                      controller: input,
                      focusNode: focus,
                      minLines: 1,
                      maxLines: compact
                          ? AppBreakpoints.chatInputMaxLinesCompact
                          : AppBreakpoints.chatInputMaxLines,
                      textInputAction: TextInputAction.newline,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'اكتب سؤالك…',
                        isDense: true,
                        filled: true,
                        fillColor: taj.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: taj.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: taj.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: taj.primary.main),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _RoundIconButton(
                  icon: Icons.send_rounded,
                  tooltip: 'إرسال',
                  filled: true,
                  onTap: onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap, this.filled = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: filled ? taj.primary.main : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Icon(icon, size: 20, color: filled ? taj.primary.contrastText : taj.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.convCap, required this.onRetry});
  final double convCap;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: taj.error.lighter,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: convCap),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: taj.error.dark),
              const SizedBox(width: 10),
              Expanded(
                child: Text('تعذّر الاتصال بالمساعد. تحقق من الشبكة وأعد المحاولة.',
                    style: text.bodySmall?.copyWith(color: taj.error.dark)),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('إعادة')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel({required this.chart});
  final AnswerChart chart;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      color: taj.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: taj.textSecondary),
              const SizedBox(width: 8),
              Text('المرجع', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          AnswerChartView(chart: chart),
        ],
      ),
    );
  }
}
