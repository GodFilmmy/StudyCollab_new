import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/session_form.dart';

class CreateSessionScreen extends StatelessWidget {
  final DateTime? initialDate;
  const CreateSessionScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SessionForm(initialDate: initialDate),
    );
  }
}
