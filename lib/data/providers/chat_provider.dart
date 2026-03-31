import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<ChatMessage> _messages = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isStreaming = false; // Add specific streaming flag
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming; // Expose it
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;

  List<dynamic> _sessions = [];
  List<dynamic> get sessions => _sessions;

  // Load all chat sessions
  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _api.getChatSessions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize a chat session
  Future<void> initSession(String? analysisId) async {
    // Clear old messages immediately to prevent flash of previous chat
    _messages = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      
      // First, load existing sessions to check for duplicates
      if (analysisId != null) {
        await loadSessions(); // Load sessions first
        
        final existingSession = _sessions.firstWhere(
          (s) => s['analysis_id'] == analysisId,
          orElse: () => null,
        );
        
        if (existingSession != null) {
          // Load the existing session instead of creating a new one
          return;
        }
      }
      
      // No existing session, create a new one
      final data = await _api.createChatSession(analysisId);

      _currentSessionId = data['id'];
      
      // Load initial messages if any (restore history)
      if (data['messages'] != null) {
        _messages = (data['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
      } else {
        _messages = [];
      }
    } catch (e) {

      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load an existing session
  Future<void> loadChatSession(String sessionId) async {
    // Clear old messages immediately to prevent flash of previous chat
    _messages = [];
    _isLoading = true;
    _error = null;
    _currentSessionId = sessionId;
    notifyListeners();

    try {
      final data = await _api.getChatSession(sessionId);
      _currentSessionId = data['session']['id'];
      
      if (data['messages'] != null) {
        _messages = (data['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
      } else {
        _messages = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_currentSessionId == null) return;

    // Optimistically add user message
    final tempId = DateTime.now().toString();
    final userMsg = ChatMessage(
      id: tempId,
      content: content,
      role: 'user',
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    
    // Add placeholder assistant message
    final aiTempId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = ChatMessage(
      id: aiTempId,
      content: '', // Start empty
      role: 'assistant',
      createdAt: DateTime.now(),
    );
    _messages.add(aiMsg);
    
    _isLoading = true;
    _isStreaming = true; // Set streaming flag
    notifyListeners();

    try {
      final stream = _api.streamChatResponse(_currentSessionId!, content);
      
      String fullContent = '';
      
      await for (final chunk in stream) {
        fullContent += chunk;
        
        // Update the last message (assistant)
        final index = _messages.indexWhere((m) => m.id == aiTempId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: aiTempId,
            content: fullContent,
            role: 'assistant',
            createdAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      // Remove the partial message if failed? Or keep partial?
      // For now keep partial or show error
    } finally {
      _isLoading = false;
      _isStreaming = false; // Reset streaming flag
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _api.deleteChatSession(sessionId);
      _sessions.removeWhere((s) => s['id'] == sessionId);
      if (_currentSessionId == sessionId) {
        _messages = [];
        _currentSessionId = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
