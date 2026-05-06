import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagingProvider>().seed();
      context.read<MessagingProvider>().seedGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messaging = context.watch<MessagingProvider>();
    final dmUnread = messaging.conversations
        .fold<int>(0, (sum, c) => sum + c.unreadCount);
    final grpUnread = messaging.groupConversations
        .fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Messages'),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Individual'),
                        if (dmUnread > 0) ...[
                          const SizedBox(width: 6),
                          _UnreadBadge(count: dmUnread),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Groups'),
                        if (grpUnread > 0) ...[
                          const SizedBox(width: 6),
                          _UnreadBadge(count: grpUnread),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IndividualTab(query: _query),
          _GroupsTab(query: _query),
        ],
      ),
    );
  }
}

// ── Unread badge ──────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Individual Tab ────────────────────────────────────────────────────────────

class _IndividualTab extends StatelessWidget {
  final String query;
  const _IndividualTab({required this.query});

  List<DmConversation> _filtered(List<DmConversation> all) {
    if (query.isEmpty) return all;
    return all
        .where((c) =>
            c.userName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final convos = context.watch<MessagingProvider>().conversations;
    final filtered = _filtered(convos);

    if (filtered.isEmpty) {
      return _EmptyState(
        icon: Icons.chat_bubble_outline,
        title: query.isNotEmpty ? 'No results found' : 'No conversations yet',
        subtitle: query.isNotEmpty
            ? 'Try a different name'
            : "Start a chat from someone's profile page",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 76, color: AppColors.border),
      itemBuilder: (ctx, i) {
        final c = filtered[i];
        return _DmTile(
          convo: c,
          timeAgo: _timeAgo(c.lastMessageTime),
          onTap: () {
            context.read<MessagingProvider>().markRead(c.userId);
            context.push('/messages/${c.userId}');
          },
        );
      },
    );
  }
}

class _DmTile extends StatelessWidget {
  final DmConversation convo;
  final String timeAgo;
  final VoidCallback onTap;
  const _DmTile(
      {required this.convo, required this.timeAgo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasUnread = convo.unreadCount > 0;
    final initial =
        convo.userName.isNotEmpty ? convo.userName[0].toUpperCase() : '?';

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.secondary,
            backgroundImage: convo.userAvatar.isNotEmpty
                ? NetworkImage(convo.userAvatar)
                : null,
            child: convo.userAvatar.isEmpty
                ? Text(initial,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16))
                : null,
          ),
          if (hasUnread)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
                child: Center(
                  child: Text('${convo.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(convo.userName,
                style: tt.labelLarge?.copyWith(
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(timeAgo,
              style: tt.labelSmall?.copyWith(
                  color: hasUnread ? AppColors.accent : AppColors.hint)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(convo.lastMessage,
                style: tt.bodyMedium?.copyWith(
                  color: hasUnread ? AppColors.text : AppColors.hint,
                  fontWeight:
                      hasUnread ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '${convo.unreadCount} DM${convo.unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Groups Tab ────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  final String query;
  const _GroupsTab({required this.query});

  List<GroupConversation> _filtered(List<GroupConversation> all) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((c) =>
            c.sessionTitle.toLowerCase().contains(q) ||
            c.subject.toLowerCase().contains(q))
        .toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<MessagingProvider>().groupConversations;
    final filtered = _filtered(groups);

    if (filtered.isEmpty) {
      return _EmptyState(
        icon: Icons.group_outlined,
        title: query.isNotEmpty ? 'No results found' : 'No group chats yet',
        subtitle: query.isNotEmpty
            ? 'Try a different name'
            : 'Join a session to access its group chat',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 76, color: AppColors.border),
      itemBuilder: (ctx, i) {
        final g = filtered[i];
        return _GroupTile(
          group: g,
          timeAgo: _timeAgo(g.lastMessageTime),
          onTap: () => context.push('/session/${g.sessionId}/chat'),
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupConversation group;
  final String timeAgo;
  final VoidCallback onTap;
  const _GroupTile(
      {required this.group, required this.timeAgo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasUnread = group.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: group.subjectColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.group_rounded,
                  color: group.subjectColor, size: 26),
            ),
          ),
          if (hasUnread)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: Center(
                  child: Text('${group.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(group.sessionTitle,
                style: tt.labelLarge?.copyWith(
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(timeAgo,
              style: tt.labelSmall?.copyWith(
                  color: hasUnread ? AppColors.error : AppColors.hint)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: group.subjectColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(group.subject,
                    style: TextStyle(
                        color: group.subjectColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text('${group.memberCount} members',
                  style: tt.labelSmall?.copyWith(color: AppColors.hint)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${group.lastSenderName}: ${group.lastMessage}',
            style: tt.bodyMedium?.copyWith(
              color: hasUnread ? AppColors.text : AppColors.hint,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(40)),
            child: Icon(icon, size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(title, style: tt.displaySmall),
          const SizedBox(height: 6),
          Text(subtitle,
              style: tt.bodyMedium?.copyWith(color: AppColors.hint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
