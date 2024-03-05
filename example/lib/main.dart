import 'package:flutter/material.dart';
import 'package:llm_lab_sdk_flutter/model/message_item.dart';
import 'package:llm_lab_sdk_flutter/service/llm_lab_sdk.dart';

void main() {
  runApp(MySocialMediaApp());
}

class MySocialMediaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Social Media App',
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

  final llmLab = LLMLabSDK();

  bool isLoading = false;

  @override
  void initState() {
    messages = [];
    llmLab.setApiKey('');

    ///api key
    // llmLab.chatWithAgentFuture(
    //   model: '28901f3d-cda7-49b9-83fa-b4855897b990',
    //   messages: messages,
    // );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
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

  void onSubmit({
    required String userInput,
    required BuildContext context,
  }) async {
    messages.add(LlmChatMessage.user(message: userInput));
    setState(() {});

    bool firstResponseReceived = false;
    void handleInitialResponse(ChatStreamResponse response) {
      messages.add(LlmChatMessage.assistant(message: response.response));
      firstResponseReceived = true;
    }

    void handleSystemPrompt(ChatStreamResponse response) {
      if (response.systemPrompt.isNotEmpty) {
        final index = messages.indexWhere((e) => e.type == 'system');
        if (index != -1) {
          messages[index] =
              LlmChatMessage.system(message: response.systemPrompt);
        } else {
          messages.add(LlmChatMessage.system(message: response.systemPrompt));
        }
      }
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
        handleSystemPrompt(response);
        handleAssistantResponse(response);
      }
    }

    llmLab
        .chatWithAgentStream(
          model: '',

          ///agent id
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
