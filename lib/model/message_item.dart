library llm_lab;

class MessageItem {
  final String? role;
  final String? content;

  MessageItem({required this.role, required this.content});

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      role: json['role'],
      content: json['content'],
    );
  }
}

class ChatStreamResponse {
  final String response;
  final String systemPrompt;

  ChatStreamResponse({required this.response, required this.systemPrompt});

  factory ChatStreamResponse.fromJson(Map<String, dynamic> json) {
    return ChatStreamResponse(
      response: json['response'] ?? '',
      systemPrompt: json['systemPrompt'] ?? '',
    );
  }
}
