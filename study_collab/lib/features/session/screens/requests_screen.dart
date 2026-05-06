import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  final String sessionId;
  const RequestsScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Requests – coming soon')));
}
