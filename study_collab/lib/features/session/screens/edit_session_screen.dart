import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import '../widgets/session_form.dart';

class EditSessionScreen extends StatelessWidget {
  final String id;
  const EditSessionScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final session = context
        .read<SessionsProvider>()
        .sessions
        .where((s) => s.id == id)
        .firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Session')),
        body: const Center(child: Text('Session not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Session')),
      body: SessionForm(
        initialSession: session,
        onDelete: () => _confirmDelete(context, session),
      ),
    );
  }

  void _confirmDelete(BuildContext context, StudySession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(title: session.title),
    );
    if (confirmed == true && context.mounted) {
      context.read<SessionsProvider>().removeSession(session.id);
      context.go('/home');
    }
  }
}

class _DeleteDialog extends StatelessWidget {
  final String title;
  const _DeleteDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Delete Session',
                style: tt.titleLarge?.copyWith(color: AppColors.error)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete:',
              style: tt.bodyMedium?.copyWith(color: AppColors.hint)),
          const SizedBox(height: 6),
          Text('"$title"',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Text('This action cannot be undone.',
                    style: tt.labelSmall?.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.hint)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size(80, 40),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
