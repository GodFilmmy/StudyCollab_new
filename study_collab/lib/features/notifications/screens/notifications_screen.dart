import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedMock());
  }

  void _seedMock() {
    final p = context.read<NotificationsProvider>();
    if (p.notifications.isNotEmpty) return;
    final now = DateTime.now();
    final data = [
      AppNotification(
        id: 'n-1',
        title: 'Join Request',
        body: 'Alex Johnson wants to join your CS101 Final Exam Prep session',
        type: NotificationType.joinRequest,
        createdAt: now.subtract(const Duration(minutes: 5)),
        targetId: 'mock-1',
      ),
      AppNotification(
        id: 'n-2',
        title: 'Request Approved',
        body:
            'Your request to join Calculus II Study Group was approved!',
        type: NotificationType.requestApproved,
        createdAt: now.subtract(const Duration(hours: 1)),
        targetId: 'mock-2',
      ),
      AppNotification(
        id: 'n-3',
        title: 'Session Starting Soon',
        body: 'CS101 Final Exam Prep starts in 1 hour',
        type: NotificationType.sessionStartingSoon,
        createdAt: now.subtract(const Duration(hours: 2)),
        targetId: 'mock-1',
      ),
      AppNotification(
        id: 'n-4',
        title: 'Starting Now!',
        body:
            'Organic Chemistry Review starts in 1 minute — get ready!',
        type: NotificationType.sessionStartingSoon,
        createdAt: now.subtract(const Duration(hours: 3)),
        targetId: 'mock-4',
      ),
      AppNotification(
        id: 'n-5',
        title: 'Session Tomorrow',
        body:
            'Reminder: Quantum Mechanics Deep Dive is scheduled for tomorrow',
        type: NotificationType.general,
        createdAt: now.subtract(const Duration(days: 1)),
        targetId: 'mock-3',
        isRead: true,
      ),
      AppNotification(
        id: 'n-6',
        title: 'Friend Request',
        body: 'Priya Sharma sent you a friend request',
        type: NotificationType.friendRequest,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        targetId: 'host-2',
      ),
    ];
    for (final n in data) {
      p.add(n);
    }
  }

  // ── Grouping ────────────────────────────────────────────────────────────────

  Map<String, List<AppNotification>> _group(
      List<AppNotification> list) {
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<AppNotification>>{};
    for (final n in list) {
      final d = DateTime(
          n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final key = d == today
          ? 'Today'
          : d == yesterday
              ? 'Yesterday'
              : 'Earlier';
      groups.putIfAbsent(key, () => []).add(n);
    }
    return groups;
  }

  List<String> _orderedKeys(Iterable<String> keys) {
    const order = ['Today', 'Yesterday', 'Earlier'];
    return order.where(keys.contains).toList();
  }

  // ── Navigation / actions ────────────────────────────────────────────────────

  void _handleTap(AppNotification n) {
    context.read<NotificationsProvider>().markRead(n.id);
    final id = n.targetId;
    if (id == null) return;
    switch (n.type) {
      case NotificationType.joinRequest:
      case NotificationType.requestApproved:
      case NotificationType.sessionStartingSoon:
      case NotificationType.general:
        context.push('/session/$id');
      case NotificationType.friendRequest:
        context.push('/user/$id');
    }
  }

  void _handleApprove(AppNotification n) {
    context.read<NotificationsProvider>().remove(n.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request approved!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleDecline(AppNotification n) {
    context.read<NotificationsProvider>().remove(n.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request declined'),
        backgroundColor: AppColors.hint,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  context.read<NotificationsProvider>().markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: AppColors.accent, fontSize: 13),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const _EmptyNotifications()
          : _buildList(notifications),
    );
  }

  Widget _buildList(List<AppNotification> notifications) {
    final groups = _group(notifications);
    final keys = _orderedKeys(groups.keys);

    return ListView(
      children: [
        for (final key in keys) ...[
          _GroupHeader(title: key),
          for (final n in groups[key]!)
            _NotificationTile(
              notification: n,
              onTap: () => _handleTap(n),
              onApprove: n.type == NotificationType.joinRequest
                  ? () => _handleApprove(n)
                  : null,
              onDecline: n.type == NotificationType.joinRequest
                  ? () => _handleDecline(n)
                  : null,
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.hint,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NStyle {
  final Color color;
  final IconData icon;
  const _NStyle(this.color, this.icon);
}

_NStyle _styleFor(AppNotification n) {
  switch (n.type) {
    case NotificationType.joinRequest:
      return const _NStyle(Color(0xFF5186CD), Icons.notifications_outlined);
    case NotificationType.requestApproved:
      return const _NStyle(AppColors.success, Icons.check_circle_outline);
    case NotificationType.sessionStartingSoon:
      final urgent = n.body.toLowerCase().contains('minute') ||
          n.title.toLowerCase().contains('now');
      return _NStyle(
        urgent ? AppColors.error : AppColors.warning,
        Icons.access_time_outlined,
      );
    case NotificationType.friendRequest:
      return const _NStyle(Color(0xFF5186CD), Icons.person_add_outlined);
    case NotificationType.general:
      return const _NStyle(AppColors.hint, Icons.event_outlined);
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final style = _styleFor(notification);
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? AppColors.secondary : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon,
                      color: style.color, size: 20),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: style.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(notification.createdAt),
                            style: tt.labelSmall,
                          ),
                          if (unread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Approve / Decline buttons for join requests
            if (onApprove != null && onDecline != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          side: const BorderSide(
                              color: AppColors.error),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        onPressed: onDecline,
                        child: const Text('Decline',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          backgroundColor:
                              const Color(0xFF5186CD),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        onPressed: onApprove,
                        child: const Text('Approve',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(48),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 44,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text('All caught up!', style: tt.displaySmall),
          const SizedBox(height: 8),
          Text(
            'No new notifications right now',
            style: tt.bodyMedium?.copyWith(color: AppColors.hint),
          ),
        ],
      ),
    );
  }
}
