import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

// Re-export the helper so the file is self-contained.
StudySession _copySession(
  StudySession s, {
  List<Member>? members,
  List<JoinRequest>? requests,
  int? joined,
}) =>
    StudySession(
      id: s.id,
      title: s.title,
      subject: s.subject,
      subjectColor: s.subjectColor,
      hostName: s.hostName,
      hostAvatar: s.hostAvatar,
      hostId: s.hostId,
      date: s.date,
      startTime: s.startTime,
      endTime: s.endTime,
      location: s.location,
      description: s.description,
      capacity: s.capacity,
      joined: joined ?? s.joined,
      visibility: s.visibility,
      hashtags: s.hashtags,
      members: members ?? s.members,
      requests: requests ?? s.requests,
      myStatus: s.myStatus,
    );

class RequestsScreen extends StatelessWidget {
  final String sessionId;
  const RequestsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final session = context
        .watch<SessionsProvider>()
        .sessions
        .where((s) => s.id == sessionId)
        .firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Requests')),
        body: const Center(child: Text('Session not found.')),
      );
    }

    final requests = session.requests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Join Requests'),
            if (requests.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${requests.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
      body: requests.isEmpty
          ? _EmptyRequests()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _RequestTile(
                session: session,
                request: requests[i],
              ),
            ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RequestTile extends StatelessWidget {
  final StudySession session;
  final JoinRequest request;
  const _RequestTile({required this.session, required this.request});

  void _approve(BuildContext context) {
    final provider = context.read<SessionsProvider>();
    final newMember = Member(
      id: request.userId,
      name: request.name,
      avatar: request.avatar,
    );
    provider.updateSession(_copySession(
      session,
      members: [...session.members, newMember],
      requests:
          session.requests.where((r) => r.id != request.id).toList(),
      joined: session.joined + 1,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request.name} approved!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _decline(BuildContext context) {
    final provider = context.read<SessionsProvider>();
    provider.updateSession(_copySession(
      session,
      requests:
          session.requests.where((r) => r.id != request.id).toList(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request.name} declined.'),
        backgroundColor: AppColors.hint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initial = request.name.isNotEmpty
        ? request.name[0].toUpperCase()
        : '?';
    final timeAgo = _timeAgo(request.requestedAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondary,
                backgroundImage: request.avatar.isNotEmpty
                    ? NetworkImage(request.avatar)
                    : null,
                child: request.avatar.isEmpty
                    ? Text(initial,
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.name,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Requested $timeAgo',
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.hint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  onPressed: () => _approve(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Decline'),
                  onPressed: () => _decline(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _EmptyRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 60, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text('No pending requests', style: tt.titleLarge),
            const SizedBox(height: 6),
            Text('New requests will appear here.',
                style: tt.bodyMedium?.copyWith(color: AppColors.hint),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
