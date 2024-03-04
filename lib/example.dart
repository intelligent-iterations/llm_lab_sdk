import 'package:flutter/material.dart';
import 'package:llm_chat/main.dart';
import 'package:llm_chat/model/llm_chat_message.dart';
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
    llmLab.setApiKey('sk-63d747de-1b39-48e7-8a15-fc5f37026a20');
    llmLab.chatWithAgentFuture(
      model: '28901f3d-cda7-49b9-83fa-b4855897b990',
      messages: messages,
    );
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
    final result = llmLab
        .chatWithAgentStream(
          model: '',
          messages: messages,
        )
        .listen(
          (response) async {
            if (response.isRight) {
              if (!firstResponseReceived) {
                // This is the initial response, so we add it
                messages.add(
                    LlmChatMessage.assistant(message: response.right.response));
                firstResponseReceived = true;
              } else {
                if (response.right.systemPrompt.isNotEmpty) {
                  final index = messages.indexWhere((e) => e.type == 'system');
                  // Check if a system message exists in the chat history
                  if (index != -1) {
                    messages.removeAt(index);
                    messages.insert(
                        index,
                        LlmChatMessage.system(
                            message: response.right.systemPrompt));
                  } else {
                    // If no system message exists, you might want to add it or handle it differently
                    // For example, adding it as a new message
                    messages.add(LlmChatMessage.system(
                        message: response.right.systemPrompt));
                  }
                }

                var lastAssistantMessageIndex = messages
                    .lastIndexWhere((message) => message.type == 'assistant');
                if (lastAssistantMessageIndex != -1) {
                  messages[lastAssistantMessageIndex] =
                      LlmChatMessage.assistant(
                          message:
                              (messages[lastAssistantMessageIndex].message ??
                                      '') +
                                  response.right.response);
                }
              }
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
