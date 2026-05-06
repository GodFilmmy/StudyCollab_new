import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _seedMessages();
  }

  void _seedMessages() {
    final now = DateTime.now();
    _messages = [
      ChatMessage(
        id: '1',
        senderId: 'host-1',
        senderName: 'Alex Johnson',
        senderAvatar: '',
        content: 'Hey everyone! Excited for tonight\'s session 🎉',
        sentAt: now.subtract(const Duration(hours: 3, minutes: 15)),
      ),
      ChatMessage(
        id: '2',
        senderId: 'member-1',
        senderName: 'Priya Sharma',
        senderAvatar: '',
        content: 'Same! I\'ve been going through chapters 7–9 already.',
        sentAt: now.subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        id: '3',
        senderId: 'host-1',
        senderName: 'Alex Johnson',
        senderAvatar: '',
        content: 'Perfect. We\'ll start with the problem sets, then review theory.',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 50)),
      ),
      ChatMessage(
        id: '4',
        senderId: 'member-2',
        senderName: 'Sam Lee',
        senderAvatar: '',
        content: 'Should I bring my laptop or just notes?',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      ChatMessage(
        id: '5',
        senderId: 'host-1',
        senderName: 'Alex Johnson',
        senderAvatar: '',
        content: 'Both! We might use some online resources.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 25)),
      ),
      ChatMessage(
        id: '6',
        senderId: 'member-1',
        senderName: 'Priya Sharma',
        senderAvatar: '',
        content: 'See you all there 👋',
        sentAt: now.subtract(const Duration(minutes: 20)),
      ),
    ];
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    setState(() {
      _messages.add(ChatMessage(
        id: const Uuid().v4(),
        senderId: user?.id ?? 'me',
        senderName: user?.name ?? 'You',
        senderAvatar: user?.avatar ?? '',
        content: text,
        sentAt: DateTime.now(),
      ));
      _inputCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMembers(BuildContext context, StudySession? session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${session?.joined ?? 0}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.hint,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Member list
            Expanded(
              child: _buildMemberList(context, session, scrollCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList(
      BuildContext context, StudySession? session, ScrollController ctrl) {
    final tt = Theme.of(context).textTheme;

    // Use real members if available, otherwise fall back to mock entries
    final members = (session?.members.isNotEmpty == true)
        ? session!.members
        : _mockMembersFor(session);

    if (members.isEmpty) {
      return Center(
        child: Text('No member info available',
            style: tt.bodyMedium?.copyWith(color: AppColors.hint)),
      );
    }

    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: members.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, color: AppColors.border),
      itemBuilder: (_, i) {
        final m = members[i];
        final initial =
            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?';
        return ListTile(
          onTap: () {
            Navigator.pop(context);
            context.push('/user/${m.id}');
          },
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary,
            backgroundImage:
                m.avatar.isNotEmpty ? NetworkImage(m.avatar) : null,
            child: m.avatar.isEmpty
                ? Text(initial,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15))
                : null,
          ),
          title: Row(
            children: [
              Text(m.name,
                  style: tt.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
              if (m.isHost) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Host',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          trailing: m.isHost
              ? null
              : const Icon(Icons.chevron_right_rounded,
                  color: AppColors.hint, size: 20),
        );
      },
    );
  }

  // Generates stand-in members from seeded chat messages when the session
  // has no members list populated.
  List<Member> _mockMembersFor(StudySession? session) {
    final seen = <String>{};
    return _messages
        .where((m) => seen.add(m.senderId))
        .map((m) => Member(
              id: m.senderId,
              name: m.senderName,
              avatar: m.senderAvatar,
              isHost: m.senderId == (session?.hostId ?? ''),
            ))
        .toList();
  }

  /// Interleave date separators between messages from different days.
  List<dynamic> _buildItems() {
    final sorted = [..._messages]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final items = <dynamic>[];
    DateTime? lastDate;
    for (final m in sorted) {
      final d = DateUtils.dateOnly(m.sentAt);
      if (lastDate == null || d != lastDate) {
        items.add(d);
        lastDate = d;
      }
      items.add(m);
    }
    return items;
  }

  String _dateLabel(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final session = context
        .read<SessionsProvider>()
        .sessions
        .where((s) => s.id == widget.sessionId)
        .firstOrNull;
    final myId = context.read<AuthProvider>().currentUser?.id ?? 'me';
    final items = _buildItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session?.title ?? 'Chat'),
            Text('${session?.joined ?? 0} members',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.hint)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Members',
            onPressed: () => _showMembers(context, session),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                if (item is DateTime) {
                  return _DateSeparator(label: _dateLabel(item));
                }
                final msg = item as ChatMessage;
                final isMe = msg.senderId == myId;
                return _ChatBubble(message: msg, isMe: isMe);
              },
            ),
          ),
          _InputBar(
            controller: _inputCtrl,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.hint)),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initial = message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';
    final timeStr = DateFormat('h:mm a').format(message.sentAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => context.push('/user/${message.senderId}'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary,
                backgroundImage: message.senderAvatar.isNotEmpty
                    ? NetworkImage(message.senderAvatar)
                    : null,
                child: message.senderAvatar.isEmpty
                    ? Text(initial,
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(message.senderName,
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.hint)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.accent : AppColors.secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: tt.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(timeStr,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.hint)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  void _showAttachOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.accent),
                ),
                title: const Text('Send Image'),
                subtitle: const Text('Share a photo from your gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image picker coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.attach_file_rounded,
                      color: AppColors.accent),
                ),
                title: const Text('Send File'),
                subtitle: const Text('Share a document or PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File picker coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Attachment + button
          GestureDetector(
            onTap: () => _showAttachOptions(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add, color: AppColors.accent, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide:
                      BorderSide(color: AppColors.accent, width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: AppColors.accent,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
