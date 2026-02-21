import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/features/assistant/data/models/chat_message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final palette = context.design;

    return Padding(
      padding: EdgeInsets.only(left: isUser ? 48 : 16, right: isUser ? 16 : 48, bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppDesign.primaryYellow.withValues(alpha: 0.15) : palette.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: palette.border.withValues(alpha: 0.5)),
          ),
          child: _buildContent(context, isUser, palette),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser, AppPalette palette) {
    if (message.isStreaming && message.content.isEmpty) {
      return _TypingIndicator(color: palette.textSecondary);
    }

    if (isUser) {
      return SelectableText(
        message.content,
        style: TextStyle(fontSize: 14, height: 1.45, color: palette.textPrimary),
      );
    }

    // During streaming, use plain text to avoid dropped characters
    // from MarkdownBody re-parsing partial content on every chunk.
    if (message.isStreaming) {
      return SelectableText(
        message.content,
        style: TextStyle(fontSize: 14, height: 1.45, color: palette.textPrimary),
      );
    }

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, height: 1.45, color: palette.textPrimary),
        strong: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: palette.textPrimary),
        h2: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: palette.textPrimary),
        h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: palette.textPrimary),
        listBullet: TextStyle(fontSize: 14, color: palette.textSecondary),
        code: TextStyle(fontSize: 13, color: palette.textPrimary, backgroundColor: palette.surface),
        codeblockDecoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.border.withValues(alpha: 0.5)),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        a: const TextStyle(color: AppDesign.primaryYellow, decoration: TextDecoration.underline),
        blockSpacing: 8,
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color color;

  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
