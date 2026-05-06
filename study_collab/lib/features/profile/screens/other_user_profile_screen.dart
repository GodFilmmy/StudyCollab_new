import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';
import '../../dashboard/widgets/session_card.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends State<OtherUserProfileScreen> {
  bool _isFriend = false;
  bool _friendRequested = false;

  static final _mockUsers = <String, UserProfile>{
    'host-1': const UserProfile(
        id: 'host-1',
        name: 'Alex Johnson',
        email: 'alex.johnson@university.edu',
        avatar: '',
        university: 'MIT',
        major: 'Computer Science',
        sessionsCount: 12,
        friendsCount: 8),
    'host-2': const UserProfile(
        id: 'host-2',
        name: 'Priya Sharma',
        email: 'priya.sharma@university.edu',
        avatar: '',
        university: 'Stanford',
        major: 'Mathematics',
        sessionsCount: 7,
        friendsCount: 15),
    'host-3': const UserProfile(
        id: 'host-3',
        name: 'Dr. Tanaka',
        email: 'tanaka@university.edu',
        avatar: '',
        university: 'Tokyo University',
        major: 'Physics',
        sessionsCount: 20,
        friendsCount: 5),
    'host-4': const UserProfile(
        id: 'host-4',
        name: 'Sara Müller',
        email: 'sara.muller@university.edu',
        avatar: '',
        university: 'TU Munich',
        major: 'Chemistry',
        sessionsCount: 9,
        friendsCount: 11),
    'host-5': const UserProfile(
        id: 'host-5',
        name: 'Mei Lin',
        email: 'mei.lin@university.edu',
        avatar: '',
        university: 'Peking University',
        major: 'Literature',
        sessionsCount: 6,
        friendsCount: 22),
  };

  UserProfile _resolveUser() =>
      _mockUsers[widget.userId] ??
      UserProfile(
        id: widget.userId,
        name: 'Student ${widget.userId}',
        email: '${widget.userId}@university.edu',
        avatar: '',
        university: 'University',
        major: 'Undeclared',
      );

  void _toggleFriend() {
    if (_isFriend) {
      setState(() { _isFriend = false; _friendRequested = false; });
    } else if (_friendRequested) {
      setState(() => _friendRequested = false);
    } else {
      setState(() => _friendRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final profile = _resolveUser();
    _isFriend = profile.isFriend;
  }

  @override
  Widget build(BuildContext context) {
    final user = _resolveUser();
    final allSessions = context.watch<SessionsProvider>().sessions;
    final tt = Theme.of(context).textTheme;

    final publicSessions = allSessions
        .where((s) =>
            s.hostId == widget.userId &&
            s.visibility != SessionVisibility.private)
        .toList();

    final attendedCount = allSessions
        .where((s) =>
            s.hostId == widget.userId ||
            (s.members.any((m) => m.id == widget.userId)))
        .length;

    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(user.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // Avatar + name + email
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      AppColors.accent.withValues(alpha: 0.15),
                  backgroundImage: user.avatar.isNotEmpty
                      ? NetworkImage(user.avatar)
                      : null,
                  child: user.avatar.isEmpty
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user.name, style: tt.displayMedium),
                const SizedBox(height: 2),
                Text(user.email,
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.hint)),
                if (user.university.isNotEmpty ||
                    user.major.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [user.major, user.university]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: tt.labelLarge
                        ?.copyWith(color: AppColors.hint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'Sessions',
                  value: user.sessionsCount.toString(),
                ),
                Container(
                    width: 1, height: 36, color: AppColors.border),
                _StatItem(
                  label: 'Friends',
                  value: user.friendsCount.toString(),
                ),
                Container(
                    width: 1, height: 36, color: AppColors.border),
                _StatItem(
                  label: 'Attended',
                  value: attendedCount.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _isFriend
                    ? _FriendBadge()
                    : OutlinedButton.icon(
                        onPressed: _toggleFriend,
                        icon: Icon(
                          _friendRequested
                              ? Icons.hourglass_empty_outlined
                              : Icons.person_add_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _friendRequested
                              ? 'Request Sent'
                              : 'Add Friend',
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/messages/${widget.userId}'),
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Sessions section
          Text(
            "Sessions by ${user.name.split(' ').first}",
            style: tt.titleLarge,
          ),
          const SizedBox(height: 12),
          if (publicSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_outlined,
                        size: 48, color: AppColors.disabled),
                    const SizedBox(height: 12),
                    Text('No public sessions',
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.hint)),
                  ],
                ),
              ),
            )
          else
            ...publicSessions.map((s) => _OtherUserSessionCard(session: s)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value,
            style: tt.displayMedium
                ?.copyWith(color: AppColors.accent)),
        const SizedBox(height: 2),
        Text(label,
            style:
                tt.bodyMedium?.copyWith(color: AppColors.hint)),
      ],
    );
  }
}

class _FriendBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 18, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'Friends',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session card with Join button for other user's sessions ───────────────────

class _OtherUserSessionCard extends StatelessWidget {
  final StudySession session;
  const _OtherUserSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SessionCard(session: session),
        if (session.myStatus == JoinStatus.notJoined)
          Positioned(
            right: 16,
            bottom: 28,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5186CD),
                minimumSize: const Size(80, 40),
              ),
              onPressed: () =>
                  context.push('/session/${session.id}'),
              child: const Text('Join'),
            ),
          ),
      ],
    );
  }
}
