import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "1", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "0", firstName: "Starbhak");

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messagesJson =
        messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('chat_messages', messagesJson);
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messagesJson = prefs.getStringList('chat_messages');
    if (messagesJson != null) {
      setState(() {
        messages = messagesJson
            .map((msg) => ChatMessage.fromJson(jsonDecode(msg)))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Starbhak.Ai"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    _saveMessages();

    try {
      String question = chatMessage.text;
      gemini.streamGenerateContent(question).listen((event) {
        String response = event.content?.parts?.first.text ?? "";
        ChatMessage message = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: response,
        );
        setState(() {
          messages = [message, ...messages];
        });
        _saveMessages();
      });
    } catch (e) {
      print(e);
    }
  }
}
