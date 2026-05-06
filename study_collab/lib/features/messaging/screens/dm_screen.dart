import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_providers.dart';

class DmScreen extends StatefulWidget {
  final String userId;
  const DmScreen({super.key, required this.userId});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _mockNames = <String, String>{
    'host-1': 'Alex Johnson',
    'host-2': 'Priya Sharma',
    'host-3': 'Dr. Tanaka',
    'host-4': 'Sara Müller',
    'host-5': 'Mei Lin',
  };

  String get _userName =>
      _mockNames[widget.userId] ?? 'User ${widget.userId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = context.read<MessagingProvider>();
      mp.seed();
      mp.markRead(widget.userId);
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(
            _scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    context.read<MessagingProvider>().sendMessage(
      widget.userId,
      ChatMessage(
        id: const Uuid().v4(),
        senderId: user?.id ?? 'me',
        senderName: user?.name ?? 'You',
        senderAvatar: user?.avatar ?? '',
        content: text,
        sentAt: DateTime.now(),
      ),
    );
    _inputCtrl.clear();
    _jumpToBottom();
  }

  List<dynamic> _buildItems(List<ChatMessage> msgs) {
    final sorted = [...msgs]
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
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final messages = context
        .watch<MessagingProvider>()
        .getMessages(widget.userId);
    final myId =
        context.read<AuthProvider>().currentUser?.id ?? 'me';
    final items = _buildItems(messages);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.push('/user/${widget.userId}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary,
                child: Text(
                  _userName.isNotEmpty
                      ? _userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style:
                          Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to view profile',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.hint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyDm(name: _userName)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      if (item is DateTime) {
                        return _DateSeparator(
                            label: _dateLabel(item));
                      }
                      final msg = item as ChatMessage;
                      final isMe = msg.senderId == myId ||
                          msg.senderId == 'me';
                      return _ChatBubble(
                          message: msg, isMe: isMe);
                    },
                  ),
          ),
          _InputBar(
              controller: _inputCtrl, onSend: _send),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyDm extends StatelessWidget {
  final String name;
  const _EmptyDm({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waving_hand_outlined,
              size: 48, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            'Say hi to $name!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.hint),
          ),
        ],
      ),
    );
  }
}

// ── Chat widgets (same style as session chat_screen) ──────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.hint),
            ),
          ),
          const Expanded(
              child: Divider(color: AppColors.border)),
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
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.accent
                        : AppColors.secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isMe ? 16 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: tt.bodyMedium?.copyWith(
                      color:
                          isMe ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeStr,
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.hint),
                  ),
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
              child: const Icon(Icons.add, color: AppColors.accent, size: 20),
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
