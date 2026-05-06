import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class MembersListScreen extends StatelessWidget {
  final String id;
  const MembersListScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final session = context
        .watch<SessionsProvider>()
        .sessions
        .where((s) => s.id == id)
        .firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: const Center(child: Text('Session not found.')),
      );
    }

    // Host tile + all members
    final allTiles = <_MemberTile>[
      _MemberTile(
        id: session.hostId,
        name: session.hostName,
        avatar: session.hostAvatar,
        color: session.subjectColor,
        isHost: true,
      ),
      ...session.members
          .where((m) => m.id != session.hostId)
          .map((m) => _MemberTile(
                id: m.id,
                name: m.name,
                avatar: m.avatar,
                color: session.subjectColor,
                isHost: false,
              )),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Members (${session.joined})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: allTiles.isEmpty
          ? const Center(child: Text('No members yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allTiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => allTiles[i],
            ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String id;
  final String name;
  final String avatar;
  final Color color;
  final bool isHost;

  const _MemberTile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push('/user/$id'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(initial,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ),
            if (isHost)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('HOST',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.hint, size: 20),
          ],
        ),
      ),
    );
  }
}
