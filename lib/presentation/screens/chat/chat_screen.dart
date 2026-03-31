import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async'; 
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/typewriter_markdown.dart';
import '../analysis/analysis_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? analysisId;
  final String? sessionId;

  const ChatScreen({super.key, this.analysisId, this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _analysisId;
  
  // Suggestion chips
  final List<String> _suggestions = [
    "How can I improve engagement?",
    "Explain my score details",
    "Give me a specific example",
    "What did I do well?",
  ];

  @override
  void initState() {
    super.initState();
    _analysisId = widget.analysisId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sessionId != null) {
        _loadSessionAndExtractAnalysisId();
      } else {
        context.read<ChatProvider>().initSession(widget.analysisId);
      }
    });
  }
  
  Future<void> _loadSessionAndExtractAnalysisId() async {
    final provider = context.read<ChatProvider>();
    await provider.loadChatSession(widget.sessionId!);
    
    if (provider.sessions.isNotEmpty) {
      final session = provider.sessions.firstWhere(
        (s) => s['id'] == widget.sessionId,
        orElse: () => null,
      );
      if (session != null && session['analysis_id'] != null) {
        setState(() {
          _analysisId = session['analysis_id'];
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _checkAutoScroll() {
     Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _handleSend([String? suggestion]) {
    final text = suggestion ?? _controller.text.trim();
    if (text.isEmpty) return;
    
    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
    _checkAutoScroll();
  }

  void _deleteChat() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Conversation?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently remove this chat and all its messages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppTheme.textSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        foregroundColor: isDark ? Colors.white70 : AppTheme.textSub,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final sessionId = context.read<ChatProvider>().currentSessionId;
      if (sessionId != null) {
        await context.read<ChatProvider>().deleteSession(sessionId);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _showChatOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // Delete option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteChat();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delete Conversation',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Permanently remove this chat',
                                style: TextStyle(
                                  color: AppTheme.errorColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.errorColor.withValues(alpha: 0.5), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Cancel
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white70 : AppTheme.textSub,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Coach',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textMain, 
            fontWeight: FontWeight.bold, 
            fontSize: 16
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: isDark ? Colors.white70 : AppTheme.textSub),
            onPressed: _showChatOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? Colors.grey[800] : AppTheme.borderLight, height: 1),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.messages.isNotEmpty) {
             WidgetsBinding.instance.addPostFrameCallback((_) {});
          }
          
          return Column(
            children: [
              // Analysis Link Banner
              if (_analysisId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), width: 1),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalysisScreen(analysisId: _analysisId!),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 18, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View Full Analysis',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                ),
                
              Expanded(
                child: provider.messages.isEmpty && !provider.isLoading
                    ? SingleChildScrollView(
                        child: _buildEmptyState(provider, isDark),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: provider.messages.length +
                            (provider.isLoading &&
                                    provider.messages.isNotEmpty &&
                                    provider.messages.last.role == 'user'
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.messages.length) {
                            return const TypingIndicator();
                          }

                          final message = provider.messages[index];
                          if (message.role != 'user' && message.content.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final isLatestAssistant =
                              (index == provider.messages.length - 1) &&
                                  message.role == 'assistant' &&
                                  provider.isStreaming;

                          return _buildMessageBubble(message, isDark, animate: isLatestAssistant);
                        },
                      ),
              ),

              // Input Area
              _buildInputArea(provider, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ChatProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(Icons.auto_awesome_outlined, size: 48, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
           const SizedBox(height: 16),
           Text(
            "Ask me anything about your teaching.",
             style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSub, fontSize: 14),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 24),
           Wrap(
             spacing: 8,
             runSpacing: 8,
             alignment: WrapAlignment.center,
             children: _suggestions.map((s) => _buildSuggestionChip(provider, s, isDark)).toList(),
           ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(ChatProvider provider, String text, bool isDark) {
    return ActionChip(
      label: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => _handleSend(text),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark, {bool animate = false}) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
             Container(
               margin: const EdgeInsets.only(top: 2),
               width: 32,
               height: 32,
               decoration: BoxDecoration(
                 color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(Icons.smart_toy_outlined, size: 16, color: Theme.of(context).primaryColor),
             ),
             const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor 
                    : isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                    )
                  : animate 
                      ? TypewriterMarkdown(
                          data: message.content, 
                          onComplete: () => _checkAutoScroll(),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isDark ? Colors.white : AppTheme.textMain, 
                              fontSize: 15, 
                              height: 1.5
                            ),
                            strong: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                            code: TextStyle(
                              backgroundColor: isDark ? Colors.black26 : Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputArea(ChatProvider provider, bool isDark) {
    final bool canSend = !provider.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Text field ──────────────────────────────────────────────
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about your lesson…',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.textMain,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 5,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => canSend ? _handleSend() : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Send button ─────────────────────────────────────────────
              GestureDetector(
                onTap: canSend ? _handleSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend
                        ? LinearGradient(
                            colors: [Theme.of(context).primaryColor, const Color(0xFF0EA5E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSend ? null : (isDark ? Colors.grey[800] : Colors.grey.shade200),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: provider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 44, bottom: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return FadeTransition(
              opacity: Tween(begin: 0.4, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
