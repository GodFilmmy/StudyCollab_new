import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  final String sessionId;
  const NotesScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Notes – coming soon')));
}
