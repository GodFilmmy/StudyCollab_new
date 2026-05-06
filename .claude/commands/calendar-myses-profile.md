# Build Calendar, My Sessions, and Profile Screens

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

== CALENDAR SCREEN ==
Create lib/features/calendar/screens/calendar_screen.dart
- Use table_calendar package
- Toggle between Monthly and Weekly view (segmented control top right)
- Days with sessions show colored dot indicators (subject colors)
- Tapping a day: shows list of sessions that day below the calendar
- 'Create Session' FAB (+ icon) — when tapped with a day already selected,
  pre-fills the date in create_session_screen
- Session items shown below calendar use the same session_card style
- Joined sessions sync to personal timeline (highlight in #EDE9FE background on calendar day)

== MY SESSIONS SCREEN ==
Create lib/features/my_sessions/screens/my_sessions_screen.dart
- AppBar: 'My Sessions' + search icon (same bottom sheet as dashboard)
- 3 tabs with TabBar in #5186cd indicator:
  Tab 1 — Upcoming: sessions I joined that haven't ended yet
  Tab 2 — Completed: sessions where end time has passed
  Tab 3 — My Sessions: sessions I created (I am host)
- Same session_card widget used for all tabs — tapping navigates to session_detail_screen
- Filter chips below tabs: by subject, by date range
- Empty state per tab with relevant message

== USER PROFILE SCREEN ==
Create lib/features/profile/screens/profile_screen.dart
Create lib/features/profile/screens/other_user_profile_screen.dart

OWN PROFILE:
- Avatar circle 80px (editable via image_picker) + name Headline 2 + email Body Medium
- Stats row: [Sessions] count | [Friends] count in accent color
- Edit profile fields: name, university, major, bio
- Session history list (same session_card)

OTHER USER PROFILE:
- Same layout but non-editable
- Add Friend button (outline) or Friends badge if already friends
- Direct Message button (primary) → navigates to dm_screen
- 'Sessions Attended' count + list of their public joined sessions
- 'Join Session' button on any session in the list
