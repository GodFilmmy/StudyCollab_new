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
    _notifications = _notifications.map((n) =>
      AppNotification(id:n.id,title:n.title,body:n.body,type:n.type,createdAt:n.createdAt,isRead:true)
    ).toList();
    notifyListeners();
  }
}

// ── Theme Provider ────────────────────────────
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  void toggle() { _isDark = !_isDark; notifyListeners(); }
}
