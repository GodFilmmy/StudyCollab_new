import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Chat – coming soon')));
}
