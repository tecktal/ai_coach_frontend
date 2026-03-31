import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_theme.dart';

class TypewriterMarkdown extends StatefulWidget {
  final String data;
  final Duration duration;
  final VoidCallback? onComplete;

  const TypewriterMarkdown({
    super.key,
    required this.data,
    this.duration = const Duration(milliseconds: 30), // Speed per char
    this.onComplete,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      // If data updated (streaming), verify if we just need to append
      if (widget.data.startsWith(oldWidget.data)) {
        // Continue typing from where we were
        _startTyping();
      } else {
        // Reset if completely new
        _currentIndex = 0;
        _displayedText = "";
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _timer?.cancel();
    
    // If we've already shown everything
    if (_currentIndex >= widget.data.length) {
      return;
    }

    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.data.length) {
        setState(() {
          _currentIndex++;
          _displayedText = widget.data.substring(0, _currentIndex);
        });
      } else {
        _timer?.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedText,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: AppTheme.textMain, fontSize: 16, height: 1.5),
        strong: const TextStyle(color: Color(0xFF6750A4), fontWeight: FontWeight.bold),
        h1: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 24),
        h2: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 20),
        h3: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 18),
        code: const TextStyle(
          color: AppTheme.textMain,
          backgroundColor: Color(0xFFF5F5F5),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
