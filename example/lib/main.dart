import 'package:flutter/material.dart';
import 'package:llm_lab_sdk_flutter/model/message_item.dart';
import 'package:llm_lab_sdk_flutter/service/llm_lab_sdk.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MySocialMediaApp());
}

class MySocialMediaApp extends StatelessWidget {
  const MySocialMediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<LlmChatMessage> messages;
  String? sessionId;

  final llmLab = LLMLabSDK(apiKey: ''); //apikey
  final agentId = ''; //agentId
  bool isLoading = false;
  bool isStream = true;

  @override
  void initState() {
    sessionId = const Uuid().v4();
    messages = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              streamSwitch(),
              BaseButton(
                  title: 'Vectorize Conversation',
                  onPressed: () => vectorizeConversation(context))
            ],
          ),
          Expanded(
            child: LLMChat(
              messages: messages,
              awaitingResponse: isLoading,
              controller: controller,
              onSubmit: (s) => onSubmit(userInput: s, context: context),
              scrollController: ScrollController(),
              showSystemMessage: false,
            ),
          )
        ],
      ),
    );
  }

  Widget streamSwitch() {
    return Row(children: [
      const SizedBox(width: 18),
      Switch(
          value: isStream,
          onChanged: (value) {
            setState(() {
              isStream = value;
            });
          }),
      const SizedBox(width: 4),
      Text(
        isStream ? 'Chat is a Stream' : 'Chat is not a Stream',
        style: TextStyle(fontSize: 18),
      ),
    ]);
  }

  void vectorizeConversation(BuildContext context) async {
    final messagesJson = messages.map((e) => e.toJson()).toList();
    Map<String, String> segments = {};
    for (final message in messagesJson) {
      segments[const Uuid().v4()] = message.toString();
    }
    final result = await llmLab.upsertVectors(
        collectionId: '', //collectionId
        segments: segments);
    String resultMessage = result.isRight ? 'Upsert Success!' : result.left;
    await showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(resultMessage),
            ));
    setState(() {});
  }

  void onSubmit({
    required String userInput,
    required BuildContext context,
  }) async {
    messages.add(LlmChatMessage.user(message: userInput));
    setState(() {});
    if (isStream) {
      await handleStreamResponse(userInput: userInput, context: context);
    } else {
      await handleFutureResponse(userInput: userInput, context: context);
    }
  }

  Future<void> handleFutureResponse({
    required String userInput,
    required BuildContext context,
  }) async {
    final result = await llmLab.chatWithAgentFuture(
      sessionId: sessionId,
      model: agentId,
      messages: messages,
    );
    if (result.isRight) {
      messages.add(result.right);
    } else {
      messages.add(LlmChatMessage(
          time: DateTime.now().millisecondsSinceEpoch,
          message: 'Something went wrong',
          type: 'assistant'));
    }
    setState(() {});
  }

  Future<void> handleStreamResponse({
    required String userInput,
    required BuildContext context,
  }) async {
    bool firstResponseReceived = false;
    void handleInitialResponse(ChatStreamResponse response) {
      messages.add(LlmChatMessage.assistant(message: response.response));
      firstResponseReceived = true;
    }

    void handleAssistantResponse(ChatStreamResponse response) {
      var lastAssistantMessageIndex =
          messages.lastIndexWhere((message) => message.type == 'assistant');
      if (lastAssistantMessageIndex != -1) {
        messages[lastAssistantMessageIndex] = LlmChatMessage.assistant(
          message: (messages[lastAssistantMessageIndex].message ?? '') +
              response.response,
        );
      }
    }

    void handleResponse(ChatStreamResponse response) {
      if (!firstResponseReceived) {
        handleInitialResponse(response);
      } else {
        handleAssistantResponse(response);
      }
    }

    llmLab
        .chatWithAgentStream(
          sessionId: sessionId,
          model: agentId, // agent id
          messages: messages,
        )
        .listen(
          (response) async {
            if (response.isRight) {
              handleResponse(response.right);
              setState(() {});
            } else {
              debugPrint('streamChatWithAgent returned left');
            }
          },
          onDone: () {},
          onError: (error) {
            debugPrint('Error from streamChatWithAgent: $error');
          },
        );
  }
}

class BaseButton extends StatelessWidget {
  const BaseButton({super.key, required this.title, required this.onPressed});

  final String title;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
