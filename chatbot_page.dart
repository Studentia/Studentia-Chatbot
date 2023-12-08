import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/styles.dart';
import '../../reusables/input_box.dart';
import 'package:http/http.dart' as http;

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  ChatbotPageState createState() => ChatbotPageState();
}

class ChatbotPageState extends State<ChatbotPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userMessage = "";
  String chatbotMessage = "";
  List<Map<String, String>> conversation = [];
  bool isLoading = false;

  void sendMessage(String message) {
    setState(() {
      conversation.add({
        'userMessage': message,
        'chatbotMessage': message,
      });
    });
  }

  Future<void> getChatbotResponse(String prompt) async {
    prompt = prompt.toLowerCase();

    setState(() {
      isLoading = true;
      conversation.add({'userMessage': prompt});
    });

    const String functionUrl =
        'https://studentia-aichatbot-xpq4n4lrkq-uc.a.run.app';

    // Check if the question has already been asked and answered
    final querySnapshot = await _firestore
        .collection('chatbot')
        .where('userMessage', isEqualTo: prompt)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Question already answered, retrieve the answer
      final chatbotMessage = querySnapshot.docs.first.data()['chatbotMessage'];
      setState(() {
        isLoading = false;
        conversation.add({'chatbotMessage': chatbotMessage});
      });
    } else {
      // Question not answered, ask the chatbot
      final response = await http.post(
        Uri.parse(functionUrl),
        body: prompt,
        headers: {'Content-Type': 'plain/text'},
      );

      if (response.statusCode == 200) {
        // Save the question and answer in Firestore
        await _firestore.collection('chatbot').add({
          'userMessage': prompt,
          'chatbotMessage': response.body.trim(),
        });

        setState(() {
          isLoading = false;
          conversation.add({'chatbotMessage': response.body.trim()});
        });
      } else {
        setState(() {
          isLoading = false;
          conversation.add({'chatbotMessage': response.body});
        });
        throw Exception('There was a problem. Please try again later.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    var commonSpacer = screenHeight * 0.02;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * ReusableStyles.horizontalPadding),
      child: Column(
        children: [
          SizedBox(height: commonSpacer),
          Expanded(
            child: ListView.builder(
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                final message = conversation[index];
                final userMessage = message['userMessage'] ?? '';
                final chatbotMessage = message['chatbotMessage'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userMessage.isNotEmpty) UserMessages(userMessage),
                    if (chatbotMessage.isNotEmpty)
                      ChatbotMessages(chatbotMessage),
                  ],
                );
              },
            ),
          ),
          isLoading
              ? const LinearProgressIndicator()
              : InputBox.onChatbot(
                  onSendBotMessage: getChatbotResponse,
                  category: InputBoxCategory.chatbot,
                ),
        ],
      ),
    );
  }
}

class UserMessages extends StatelessWidget {
  final String message;

  const UserMessages(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    var commonSpacer = screenHeight * 0.02;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.only(left: screenWidth * 0.12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  width: screenHeight * 0.0007,
                  color: ReusableStyles.toolBarBorder,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(ReusableStyles.radius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenHeight * 0.02,
                  vertical: screenHeight * 0.014,
                ),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: commonSpacer),
      ],
    );
  }
}

class ChatbotMessages extends StatelessWidget {
  final String message;

  const ChatbotMessages(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    var commonSpacer = screenHeight * 0.02;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: Container(
              margin: EdgeInsets.only(right: screenWidth * 0.12),
              constraints: BoxConstraints(
                maxWidth: screenHeight * 0.7,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: ReusableStyles.gradientColors,
                ),
                borderRadius: BorderRadius.circular(ReusableStyles.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(0.7),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(ReusableStyles.radius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: commonSpacer,
                        vertical: screenHeight * 0.014),
                    child: Center(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: commonSpacer),
      ],
    );
  }
}
