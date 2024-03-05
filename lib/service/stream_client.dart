import "dart:async";
import "dart:convert";

import "package:flutter/cupertino.dart";
import 'package:http/http.dart' as http;
import "package:llm_lab_sdk_flutter/util/streaming_default.dart"
    if (dart.library.js) 'package:llm_lab_sdk_flutter/util/streaming_web.dart'
    if (dart.library.io) 'package:llm_lab_sdk_flutter/util/streaming_io.dart';

import "../model/message_item.dart";

const getMethod = 'GET';
const postMethod = 'POST';
const streamResponseStart = "data: ";
const streamResponseEnd = "undefined";
const errorFieldKey = 'error';
const messageFieldKey = 'message';

@protected
@immutable
abstract class StreamClient {
  static http.Client _streamingHttpClient() {
    return createClient();
  }

  static Stream<T> postChatStream<T>({
    required String fullPath,
    required String apiKey,
    required T Function(ChatStreamResponse) onSuccess,
    required T Function(String) onError,
    required Map<String, dynamic> body,
  }) {
    final controller = StreamController<T>();
    final uri = Uri.parse(fullPath);
    final headers = {
      'apiKey': apiKey,
      'Content-Type': 'application/json',
    };

    _streamingHttpClient()
        .send(http.Request('POST', uri)
          ..headers.addAll(headers)
          ..body = jsonEncode(body))
        .then((response) {
      readStream(response.stream, controller, onSuccess, onError);
    }).catchError((error) {
      onError(error.toString());
    });

    return controller.stream;
  }

  static void readStream(
    Stream<List<int>> byteStream,
    StreamController controller,
    Function(ChatStreamResponse) onSuccess,
    Function(String) onError,
  ) {
    byteStream.listen((byteChunk) {
      final String decodedChunk = utf8.decode(byteChunk);

      final List<String> lines = decodedChunk.split('\n');

      processAndEmitData(controller, lines, onSuccess, onError);
    }, onError: (error) {
      onError(error.toString());
      controller.addError(Exception('Stream error: $error'));
    }, onDone: () {
// Handle stream completion
      controller.close();
    });
  }
}

Future<void> processAndEmitData(
    StreamController controller,
    List<String> dataLines,
    Function(ChatStreamResponse) onSuccess,
    Function(String) onError) async {
  for (String line in dataLines) {
    if (line.isEmpty || !line.startsWith(streamResponseStart)) {
      continue;
    }

    final String jsonData = line.substring(streamResponseStart.length);
    if (jsonData.contains('statusCode')) {
      controller.add(onError(jsonData));
      continue;
    }
    if (jsonData.contains(streamResponseEnd)) {
      debugPrint('Stream done');
      controller.close();
      return;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonData);
      final chatResponse = ChatStreamResponse.fromJson(decoded);
      controller.add(onSuccess(chatResponse));
    } catch (e) {}
  }
}
