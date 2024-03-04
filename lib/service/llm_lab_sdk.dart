import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:llm_chat/model/llm_chat_message.dart';

import '../model/agent.dart';
import '../model/message_item.dart';
import 'stream_client.dart';

class LLMLabSDK {
  String apiKey = '';

  void setApiKey(String apiKey) {
    this.apiKey = apiKey;
  }

  Future<void> chatWithAgentFuture(
      {required String model, required List<LlmChatMessage> messages}) async {}

  final tag = 'LLMLabSDK';
  final path = 'agent-chat';
  Map<String, Agent> agent = {};
  final baseUrl = 'https://launch-api.com';

  Future<Either<String, Agent>> loadAgent({required String apiKey}) async {
    if (agent.isNotEmpty) {
      return Right(agent.values.first);
    }
    try {
      final response = await get(
        headers: {
          'apiKey': apiKey,
          'Content-Type': 'application/json',
        },
        Uri.parse('$baseUrl/agent/fda3c864-bc7b-42ed-b139-198f9b215165'),
      );
      final _agent = Agent.fromJson(json.decode(response.body));
      agent[_agent.id ?? ''] = _agent;
      return Right(_agent);
    } catch (e) {
      return Left('Exception occurred: $e');
    }
  }

  Stream<Either<String, ChatStreamResponse>> chatWithAgentStream({
    required String model,
    required List<LlmChatMessage> messages,
    double temperature = 0.0,
  }) async* {
    try {
      final stream = StreamClient.postChatStream(
        apiKey: apiKey,
        fullPath: '$baseUrl/$path/chat/completion',
        body: {
          "model": model,
          "messages": messages
              .map((e) => {'role': e.type, 'content': e.message ?? ''})
              .toList(),
        },
        onSuccess: (ChatStreamResponse response) {
          debugPrint(
              'postStream on success response content: ${response.response}');
          return response;
        },
        onError: (error) {
          debugPrint('streamAiChat onError callback: $error');
          return error;
        },
      );

      await for (var event in stream) {
        if (event is ChatStreamResponse) {
          yield Right(event);
        } else {
          debugPrint('streamAiChat yielding left');
          yield Left(event.toString());
        }
      }
    } catch (e) {
      debugPrint('chatWithAgent yielding left on exception $e');
      yield Left(e.toString());
    }
  }
}
