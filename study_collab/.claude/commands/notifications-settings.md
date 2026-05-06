# Build Notifications and Settings Screens

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

== NOTIFICATIONS SCREEN ==
Create lib/features/notifications/screens/notifications_screen.dart
- Grouped notification list
- 5 notification types with different icons and colors:
  🔔 Join Request (for host) — accent #5186cd — Approve/Decline inline buttons
  ✅ Request Approved — success #38a169
  ⏰ Session starting in 1 hour — warning #d69e2e
  ⏰ Session starting in 1 minute — error #e53e3e
  📅 Session tomorrow — hint #888888
  👥 Friend request — accent
- Unread notifications: #EDE9FE background; read: white background
- Mark all as read button in AppBar
- Tapping notification navigates to relevant screen

== SETTINGS SCREEN ==
Create lib/features/settings/screens/settings_screen.dart
- Profile section: avatar + name + email + 'Edit Profile' button
- Notifications section: toggle switches for:
  Join request alerts | Session reminders | Friend requests | All notifications
- Appearance section: Light/Dark mode toggle (dark mode uses #1a1a2e as background)
- Account section: Change password button, Sign Out button (#e53e3e text)
- All toggles use #5186cd active track color
