import 'package:flutter/material.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('User Profile – coming soon')));
}
