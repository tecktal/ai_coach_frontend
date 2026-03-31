class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      role: json['role'] == 'model' ? 'assistant' : json['role'], // Map 'model' to 'assistant' if needed
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUser => role == 'user';
}
