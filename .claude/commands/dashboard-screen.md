# Build Dashboard / Study Hub Screen

Read all files in lib/core/theme/ and lib/models/models.dart first.

Create lib/features/dashboard/screens/dashboard_screen.dart
Create lib/features/dashboard/widgets/session_card.dart
Create lib/features/dashboard/widgets/search_bottom_sheet.dart
Create lib/features/dashboard/widgets/join_password_dialog.dart
Create lib/features/dashboard/widgets/join_request_dialog.dart

HEADER (AppBar area):
- Greeting: 'Good morning, [Name] 👋' in Headline Small (18px 500)
- Subtitle: 'Find your next study session' in Body Medium
- Notification bell icon (top right) with badge counter → navigates to notifications screen
- Search bar is NOT inline — it opens as a bottom sheet (search_bottom_sheet)
- Search bottom sheet animates up from bottom when user taps the search button
- Inside bottom sheet: search input at top, then filter chips: All / Subject / Hostname / #Hashtag
- Smart filter: detect '#' prefix → hashtag mode, '@' prefix → hostname mode

SESSION CARD (session_card.dart) — reuse this widget on every page:
- White card, border #d4d4d4, borderRadius 12, padding 16
- Top row: colored subject label pill (accent color matching subject) + session title (Title Large)
- Host row: CircleAvatar 32px + host name (Body Medium) + date/time (Label Small, hint color)
- Location row: 📍 icon + location text (Body Medium)
- Description if present: Body Medium, hint color, max 2 lines
- Progress bar: show filled slots / total capacity using LinearProgressIndicator
  color: #5186cd, backgroundColor: #EDE9FE, borderRadius 4
  label: '[X] / [Y] spots remaining' in Label Small
- JOIN BUTTON area (bottom right) — 3 variants:
  1. PUBLIC: Primary button 'Join' (48px, #5186cd)
  2. APPROVAL: Outline button 'Request to Join' → tapping shows join_request_dialog
     Dialog: confirm message + submit → show success snackbar 'Request sent!'
  3. PRIVATE: Lock icon on card corner + 'Join with Password' button → join_password_dialog
     Dialog: password input + submit
- Already joined: show 'Joined ✓' chip in green
- Pending: show 'Pending...' chip in warning color

BODY:
- ListView of session_card widgets
- Pull to refresh gesture
- Empty state: illustration + 'No sessions yet' text
