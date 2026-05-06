import 'package:flutter/material.dart';

class DmScreen extends StatelessWidget {
  final String userId;
  const DmScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('DM – coming soon')));
}
