# Build Navigation Shell and Direct Messages Screen

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

== NAVIGATION SHELL ==
Create lib/core/widgets/main_shell.dart
- BottomNavigationBar with 5 tabs:
  🏠 Home (dashboard) | 📅 Calendar | ➕ Create (FAB center) | 📚 My Sessions | 👤 Profile
- Center ➕ button is a FloatingActionButton docked into the bottom nav
  It navigates to create_session_screen
- Selected tab: #5186cd icon + label; unselected: #888888
- Notification badge on Home tab when there are unread notifications

== DIRECT MESSAGES SCREEN ==
Create lib/features/messaging/screens/dm_list_screen.dart
Create lib/features/messaging/screens/dm_screen.dart

DM LIST: Accessible from profile screen or notification
- List of conversations: avatar + name + last message preview + timestamp
- Unread badge on conversations
- Search bar to filter conversations

DM SCREEN (single chat):
- Same chat bubble style as group chat in session
- Input bar pinned above keyboard
- AppBar shows other user's avatar + name — tapping name navigates to their profile
