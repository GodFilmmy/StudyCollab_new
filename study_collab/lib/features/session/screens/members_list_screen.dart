import 'package:flutter/material.dart';

class MembersListScreen extends StatelessWidget {
  final String id;
  const MembersListScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Members – coming soon')));
}
