import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

StudySession _copySession(
  StudySession s, {
  List<Member>? members,
  List<JoinRequest>? requests,
  int? joined,
  JoinStatus? myStatus,
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
      myStatus: myStatus ?? s.myStatus,
    );

// ── Screen ────────────────────────────────────────────────────────────────────

class SessionDetailScreen extends StatelessWidget {
  final String id;
  const SessionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final session = context
        .watch<SessionsProvider>()
        .sessions
        .where((s) => s.id == id)
        .firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Session not found.')),
      );
    }

    final tt = Theme.of(context).textTheme;
    final isHost = session.myStatus == JoinStatus.host;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          _ThreeDotMenu(session: session, isHost: isHost),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject pill
            _SubjectPill(session: session),
            const SizedBox(height: 10),
            // Title
            Text(session.title, style: tt.displayMedium),
            const SizedBox(height: 20),
            // Host card
            _HostCard(session: session, tt: tt),
            const SizedBox(height: 16),
            // Info chips
            _InfoChipsRow(session: session, tt: tt),
            // Description
            if (session.description != null &&
                session.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(session.description!,
                  style: tt.bodyMedium?.copyWith(color: AppColors.hint)),
            ],
            const SizedBox(height: 16),
            // Progress
            _ProgressSection(session: session, tt: tt),
            const SizedBox(height: 24),
            // Members row
            _MembersRow(session: session, tt: tt),
            const SizedBox(height: 20),
            // Action buttons
            _ActionButtons(session: session),
            // Requests section (host + approval only)
            if (isHost &&
                session.visibility == SessionVisibility.approval) ...[
              const SizedBox(height: 24),
              _RequestsSection(session: session, tt: tt),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 3-dot menu ────────────────────────────────────────────────────────────────

class _ThreeDotMenu extends StatelessWidget {
  final StudySession session;
  final bool isHost;
  const _ThreeDotMenu({required this.session, required this.isHost});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) => _onSelected(context, val),
      itemBuilder: (_) => isHost ? _hostItems() : _joinerItems(),
    );
  }

  List<PopupMenuEntry<String>> _hostItems() => [
        _menuItem('edit', Icons.edit_outlined, 'Edit Session', AppColors.text),
        _menuItem('delete', Icons.delete_outline, 'Delete Session',
            AppColors.error),
        const PopupMenuDivider(),
        _menuItem('copy', Icons.link_outlined, 'Copy Invite Link',
            AppColors.text),
      ];

  List<PopupMenuEntry<String>> _joinerItems() => [
        _menuItem('leave', Icons.exit_to_app_outlined, 'Leave Session',
            AppColors.error),
        const PopupMenuDivider(),
        _menuItem('copy', Icons.link_outlined, 'Copy Invite Link',
            AppColors.text),
      ];

  PopupMenuItem<String> _menuItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, String val) async {
    switch (val) {
      case 'edit':
        context.push('/session/${session.id}/edit');
      case 'delete':
        final ok = await _confirm(context, 'Delete Session',
            'Delete "${session.title}"? This cannot be undone.', 'Delete',
            isDestructive: true);
        if (ok && context.mounted) {
          context.read<SessionsProvider>().removeSession(session.id);
          context.go('/home');
        }
      case 'leave':
        final ok = await _confirm(context, 'Leave Session',
            'Leave "${session.title}"?', 'Leave',
            isDestructive: true);
        if (ok && context.mounted) {
          final provider = context.read<SessionsProvider>();
          final auth = context.read<AuthProvider>();
          final uid = auth.currentUser?.id ?? '';
          final updated = _copySession(
            session,
            members: session.members.where((m) => m.id != uid).toList(),
            joined: (session.joined - 1).clamp(0, session.capacity),
            myStatus: JoinStatus.notJoined,
          );
          provider.updateSession(updated);
          context.pop();
        }
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
              text: 'https://studycollab.app/join/${session.id}'),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite link copied!')),
          );
        }
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
    String action, {
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.hint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.error : AppColors.accent,
              minimumSize: const Size(80, 38),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Section widgets ───────────────────────────────────────────────────────────

class _SubjectPill extends StatelessWidget {
  final StudySession session;
  const _SubjectPill({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = session.subjectColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        session.subject,
        style: TextStyle(
            color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  final StudySession session;
  final TextTheme tt;
  const _HostCard({required this.session, required this.tt});

  @override
  Widget build(BuildContext context) {
    final initial = session.hostName.isNotEmpty
        ? session.hostName[0].toUpperCase()
        : '?';
    return GestureDetector(
      onTap: () => context.push('/user/${session.hostId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  session.subjectColor.withValues(alpha: 0.15),
              backgroundImage: session.hostAvatar.isNotEmpty
                  ? NetworkImage(session.hostAvatar)
                  : null,
              child: session.hostAvatar.isEmpty
                  ? Text(initial,
                      style: TextStyle(
                          color: session.subjectColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.hostName, style: tt.titleLarge),
                  Text('Session Host',
                      style:
                          tt.bodyMedium?.copyWith(color: AppColors.hint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.hint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoChipsRow extends StatelessWidget {
  final StudySession session;
  final TextTheme tt;
  const _InfoChipsRow({required this.session, required this.tt});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(session.date);
    final startStr = DateFormat('h:mm a').format(session.startTime);
    final endStr = DateFormat('h:mm a').format(session.endTime);
    final visLabel = switch (session.visibility) {
      SessionVisibility.public => '🌐 Public',
      SessionVisibility.approval => '✋ Approval',
      SessionVisibility.private => '🔒 Private',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(emoji: '📅', text: dateStr),
        _InfoChip(emoji: '⏰', text: '$startStr – $endStr'),
        _InfoChip(emoji: '📍', text: session.location),
        _InfoChip(emoji: '', text: visLabel),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String emoji;
  final String text;
  const _InfoChip({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        emoji.isNotEmpty ? '$emoji $text' : text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.text, fontSize: 12),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final StudySession session;
  final TextTheme tt;
  const _ProgressSection({required this.session, required this.tt});

  static const Color _bar = Color(0xFF5186CD);

  @override
  Widget build(BuildContext context) {
    final remaining = session.capacity - session.joined;
    final progress = session.capacity > 0
        ? (session.joined / session.capacity).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            color: _bar,
            backgroundColor: AppColors.secondary,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text('$remaining / ${session.capacity} spots remaining',
            style: tt.labelSmall),
      ],
    );
  }
}

class _MembersRow extends StatelessWidget {
  final StudySession session;
  final TextTheme tt;
  const _MembersRow({required this.session, required this.tt});

  @override
  Widget build(BuildContext context) {
    // Build avatar list: host first, then members
    final avatars = <({String name, String avatar})>[
      (name: session.hostName, avatar: session.hostAvatar),
      ...session.members.take(4).map((m) => (name: m.name, avatar: m.avatar)),
    ];
    final extra = (session.joined - avatars.length).clamp(0, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Members (${session.joined})', style: tt.titleLarge),
            TextButton(
              onPressed: () =>
                  context.push('/session/${session.id}/members'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              height: 38,
              width:
                  (avatars.length * 26.0 + 14).clamp(0.0, double.infinity),
              child: Stack(
                children: avatars.asMap().entries.map((e) {
                  final a = e.value;
                  final initial = a.name.isNotEmpty
                      ? a.name[0].toUpperCase()
                      : '?';
                  return Positioned(
                    left: e.key * 26.0,
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: session.subjectColor
                          .withValues(alpha: 0.15),
                      backgroundImage: a.avatar.isNotEmpty
                          ? NetworkImage(a.avatar)
                          : null,
                      child: a.avatar.isEmpty
                          ? Text(initial,
                              style: TextStyle(
                                  color: session.subjectColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            if (extra > 0) ...[
              const SizedBox(width: 8),
              Text('+$extra more',
                  style:
                      tt.bodyMedium?.copyWith(color: AppColors.hint)),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final StudySession session;
  const _ActionButtons({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Chat'),
            onPressed: () =>
                context.push('/session/${session.id}/chat'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: const Text('Notes'),
            onPressed: () =>
                context.push('/session/${session.id}/notes'),
          ),
        ),
      ],
    );
  }
}

class _RequestsSection extends StatelessWidget {
  final StudySession session;
  final TextTheme tt;
  const _RequestsSection({required this.session, required this.tt});

  @override
  Widget build(BuildContext context) {
    final requests = session.requests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Join Requests', style: tt.titleLarge),
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
                        fontWeight: FontWeight.w600)),
              ),
            ],
            const Spacer(),
            if (requests.isNotEmpty)
              TextButton(
                onPressed: () => context
                    .push('/session/${session.id}/requests'),
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('No pending requests.',
                style:
                    tt.bodyMedium?.copyWith(color: AppColors.hint),
                textAlign: TextAlign.center),
          )
        else
          ...requests
              .take(2)
              .map((r) => _InlineRequestTile(
                  session: session, request: r, tt: tt)),
      ],
    );
  }
}

class _InlineRequestTile extends StatelessWidget {
  final StudySession session;
  final JoinRequest request;
  final TextTheme tt;
  const _InlineRequestTile(
      {required this.session,
      required this.request,
      required this.tt});

  @override
  Widget build(BuildContext context) {
    final initial = request.name.isNotEmpty
        ? request.name[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary,
            backgroundImage: request.avatar.isNotEmpty
                ? NetworkImage(request.avatar)
                : null,
            child: request.avatar.isEmpty
                ? Text(initial,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(request.name, style: tt.bodyMedium)),
          _ApproveBtn(session: session, request: request),
          const SizedBox(width: 6),
          _DeclineBtn(session: session, request: request),
        ],
      ),
    );
  }
}

class _ApproveBtn extends StatelessWidget {
  final StudySession session;
  final JoinRequest request;
  const _ApproveBtn({required this.session, required this.request});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<SessionsProvider>();
        final newMember = Member(
            id: request.userId,
            name: request.name,
            avatar: request.avatar);
        provider.updateSession(_copySession(
          session,
          members: [...session.members, newMember],
          requests: session.requests
              .where((r) => r.id != request.id)
              .toList(),
          joined: session.joined + 1,
        ));
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Approve',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DeclineBtn extends StatelessWidget {
  final StudySession session;
  final JoinRequest request;
  const _DeclineBtn({required this.session, required this.request});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<SessionsProvider>();
        provider.updateSession(_copySession(
          session,
          requests: session.requests
              .where((r) => r.id != request.id)
              .toList(),
        ));
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Decline',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
