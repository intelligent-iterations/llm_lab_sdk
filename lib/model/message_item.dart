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

class ChatCompletionResponse {
  final List<Choice> choices;

  ChatCompletionResponse({
    required this.choices,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      choices:
          List<Choice>.from(json['choices'].map((x) => Choice.fromJson(x))),
    );
  }
}

class Choice {
  final int index;
  final Message message;
  final String finishReason;

  Choice(
      {required this.index, required this.message, required this.finishReason});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: json['index'],
      message: Message.fromJson(json['message']),
      finishReason: json['finish_reason'],
    );
  }
}

class Message {
  final String? role;
  final String? content;

  Message({required this.role, required this.content});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
    );
  }
}
