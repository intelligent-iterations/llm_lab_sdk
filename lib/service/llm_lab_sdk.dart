library llm_lab;

import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:llm_chat/model/llm_chat_message.dart';

import '../model/message_item.dart';
import '../model/upsert_response.dart';
import 'stream_client.dart';

export 'package:llm_chat/main.dart';
export 'package:llm_chat/model/llm_chat_message.dart';
export 'package:llm_chat/model/llm_style.dart';

class LLMLabSDK {
  const LLMLabSDK({required this.apiKey});

  final String apiKey;
  final tag = 'LLMLabSDK';
  final baseUrl = 'https://launch-api.com';

  Future<Either<String, LlmChatMessage>> chatWithAgentFuture({
    required String model,
    required List<LlmChatMessage> messages,
    String? sessionId,
    String? maxTokens,
    double? temperature,
  }) async {
    try {
      final body = {
        'messages': messages
            .map((e) => {'role': e.type, 'content': e.message})
            .toList(),
        'model': model,
      };

      if (maxTokens != null) {
        body['maxTokens'] = maxTokens;
      }
      if (sessionId != null) {
        body['sessionId'] = sessionId;
      }
      if (temperature != null) {
        body['temperature'] = temperature;
      }
      final response = await post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': apiKey,
        },
        body: json.encode(body),
      );
      final parsedResponse =
          ChatCompletionResponse.fromJson(json.decode(response.body));
      final message = LlmChatMessage(
          time: DateTime.now().millisecondsSinceEpoch,
          message: parsedResponse.choices.first.message.content,
          type: parsedResponse.choices.first.message.role);
      return Right(message);
    } catch (e) {
      debugPrint('$tag chatWithAgentFuture Exception: $e');
      return Left('Exception occurred: $e');
    }
  }

  Future<Either<String, UpsertResponse>> upsertVectors(
      {required String collectionId,
      required Map<String, String>? segments}) async {
    const method = 'upsertVectors';
    try {
      debugPrint('$tag $method started');
      var body = {'segments': segments};
      final response = await post(
        Uri.parse('$baseUrl/relevantMemory/$collectionId/upsert'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': apiKey,
        },
        body: json.encode(body),
      );
      debugPrint('$tag $method success');
      final upsertResponse =
          UpsertResponse.fromJson(json.decode(response.body));
      if (upsertResponse.warning != null) {
        return Left(upsertResponse.warning ?? "Something went wrong");
      }
      return Right(upsertResponse);
    } catch (e) {
      debugPrint('$tag $method exception: $e');
      return Left('$e');
    }
  }

  Stream<Either<String, ChatStreamResponse>> chatWithAgentStream({
    required String model,
    required List<LlmChatMessage> messages,
    String? sessionId,
    int? maxTokens,
    double? temperature,
  }) async* {
    try {
      var body = {
        "stream": true,
        "sessionId": sessionId,
        "model": model,
        "messages": messages
            .map((e) => {'role': e.type, 'content': e.message ?? ''})
            .toList(),
      };
      if (maxTokens != null) {
        body['maxTokens'] = maxTokens;
      }
      if (temperature != null) {
        body['temperature'] = temperature;
      }
      final stream = StreamClient.postChatStream(
        apiKey: apiKey,
        fullPath: '$baseUrl/v1/chat/completions',
        body: body,
        onSuccess: (ChatStreamResponse response) {
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
