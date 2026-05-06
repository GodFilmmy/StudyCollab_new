import 'package:flutter/material.dart';
import '../models/models.dart';

// ── Auth Provider ─────────────────────────────
class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void login(UserProfile user) { _currentUser = user; notifyListeners(); }
  void logout() { _currentUser = null; notifyListeners(); }
  void updateProfile(UserProfile updated) { _currentUser = updated; notifyListeners(); }
}

// ── Sessions Provider ─────────────────────────
class SessionsProvider extends ChangeNotifier {
  List<StudySession> _sessions = [];
  List<StudySession> get sessions => _sessions;

  List<StudySession> get mySessions =>
    _sessions.where((s) => s.myStatus == JoinStatus.host).toList();

  List<StudySession> get joinedSessions =>
    _sessions.where((s) => s.myStatus == JoinStatus.joined).toList();

  void addSession(StudySession s) { _sessions.insert(0, s); notifyListeners(); }
  void removeSession(String id) { _sessions.removeWhere((s) => s.id == id); notifyListeners(); }
  void updateSession(StudySession updated) {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx != -1) { _sessions[idx] = updated; notifyListeners(); }
  }

  List<StudySession> search(String query) {
    if (query.isEmpty) return _sessions;
    final q = query.toLowerCase();
    if (q.startsWith('#')) {
      final tag = q.substring(1);
      return _sessions.where((s) => s.hashtags.any((h) => h.toLowerCase().contains(tag))).toList();
    }
    if (q.startsWith('@')) {
      final host = q.substring(1);
      return _sessions.where((s) => s.hostName.toLowerCase().contains(host)).toList();
    }
    return _sessions.where((s) =>
      s.title.toLowerCase().contains(q) ||
      s.subject.toLowerCase().contains(q) ||
      (s.description?.toLowerCase().contains(q) ?? false)).toList();
  }
}

// ── Notifications Provider ────────────────────
class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void add(AppNotification n) { _notifications.insert(0, n); notifyListeners(); }

  void markAllRead() {
    _notifications = _notifications.map((n) => AppNotification(
      id:n.id, title:n.title, body:n.body, type:n.type,
      createdAt:n.createdAt, isRead:true, targetId:n.targetId,
    )).toList();
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final n = _notifications[idx];
    _notifications[idx] = AppNotification(
      id:n.id, title:n.title, body:n.body, type:n.type,
      createdAt:n.createdAt, isRead:true, targetId:n.targetId,
    );
    notifyListeners();
  }

  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}

// ── Messaging Provider ────────────────────────
class MessagingProvider extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _messages = {};
  final List<DmConversation> _convos = [];

  List<DmConversation> get conversations => List.unmodifiable(_convos);
  List<ChatMessage> getMessages(String userId) =>
      List.unmodifiable(_messages[userId] ?? []);

  void seed() {
    if (_convos.isNotEmpty) return;
    final now = DateTime.now();
    _convos.addAll([
      DmConversation(userId:'host-2', userName:'Priya Sharma', userAvatar:'',
        lastMessage:'See you at the session tonight!',
        lastMessageTime:now.subtract(const Duration(minutes:10)), unreadCount:2),
      DmConversation(userId:'host-1', userName:'Alex Johnson', userAvatar:'',
        lastMessage:'Thanks for joining! Let me know if you have questions.',
        lastMessageTime:now.subtract(const Duration(hours:2)), unreadCount:0),
      DmConversation(userId:'host-4', userName:'Sara Müller', userAvatar:'',
        lastMessage:'The chemistry session is confirmed for Friday',
        lastMessageTime:now.subtract(const Duration(days:1)), unreadCount:1),
    ]);
    _messages['host-2'] = [
      ChatMessage(id:'dm-1',senderId:'host-2',senderName:'Priya Sharma',senderAvatar:'',
        content:'Hey! Are you coming to the Calculus study group?',
        sentAt:now.subtract(const Duration(hours:1))),
      ChatMessage(id:'dm-2',senderId:'me',senderName:'You',senderAvatar:'',
        content:'Yes! Looking forward to it.',
        sentAt:now.subtract(const Duration(minutes:50))),
      ChatMessage(id:'dm-3',senderId:'host-2',senderName:'Priya Sharma',senderAvatar:'',
        content:'See you at the session tonight!',
        sentAt:now.subtract(const Duration(minutes:10))),
    ];
    _messages['host-1'] = [
      ChatMessage(id:'dm-4',senderId:'host-1',senderName:'Alex Johnson',senderAvatar:'',
        content:'Welcome to the CS study group!',
        sentAt:now.subtract(const Duration(hours:3))),
      ChatMessage(id:'dm-5',senderId:'me',senderName:'You',senderAvatar:'',
        content:'Thanks! Excited to join.',
        sentAt:now.subtract(const Duration(hours:2,minutes:30))),
      ChatMessage(id:'dm-6',senderId:'host-1',senderName:'Alex Johnson',senderAvatar:'',
        content:'Thanks for joining! Let me know if you have questions.',
        sentAt:now.subtract(const Duration(hours:2))),
    ];
    _messages['host-4'] = [
      ChatMessage(id:'dm-7',senderId:'host-4',senderName:'Sara Müller',senderAvatar:'',
        content:'The chemistry session is confirmed for Friday',
        sentAt:now.subtract(const Duration(days:1))),
    ];
    notifyListeners();
  }

  void sendMessage(String userId, ChatMessage message) {
    _messages.putIfAbsent(userId, () => []).add(message);
    final idx = _convos.indexWhere((c) => c.userId == userId);
    if (idx != -1) {
      _convos[idx] = _convos[idx].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.sentAt,
        unreadCount: 0,
      );
    }
    notifyListeners();
  }

  void markRead(String userId) {
    final idx = _convos.indexWhere((c) => c.userId == userId);
    if (idx != -1 && _convos[idx].unreadCount > 0) {
      _convos[idx] = _convos[idx].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }
}

// ── Theme Provider ────────────────────────────
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  void toggle() { _isDark = !_isDark; notifyListeners(); }
}
