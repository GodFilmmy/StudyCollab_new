# Build Session Details & Interaction Screens

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

Create lib/features/session/screens/session_detail_screen.dart
Create lib/features/session/screens/members_list_screen.dart
Create lib/features/session/screens/chat_screen.dart
Create lib/features/session/screens/notes_screen.dart
Create lib/features/session/screens/requests_screen.dart

SESSION DETAIL SCREEN:
- Top: subject color pill + title Headline 2 + 3-dot menu (top right)
  3-dot menu for HOST: Edit (navigate to edit screen) | Delete | Copy Invite Link
  3-dot menu for JOINER: Leave Session | Copy Invite Link
  Delete and Leave must show confirmation dialog before action
- Host info card: CircleAvatar 48px + name Title Large + university Body Medium
- Info row chips: 📅 date | ⏰ time | 📍 location | 🔒 or 🌐 visibility
- Description text if present
- Progress bar with capacity (same style as session_card)
- Members section: title 'Members' + 'See All' link (→ members_list_screen)
  Show host avatar first + first 4 member avatars in a row (overlapping circles)
- Action buttons row:
  💬 Chat button → chat_screen
  📎 Notes button → notes_screen
- Requests tab: show ONLY if viewer is host AND session is in approval mode
  Tab shows pending join requests with Approve / Decline buttons

MEMBERS LIST SCREEN: Full scrollable list of all members including host at top (HOST badge)
  Tapping any member → navigate to their profile screen

CHAT SCREEN:
- Standard chat bubble UI: right side = current user (accent color), left = others (secondary)
- Input bar at bottom pinned above keyboard
- Messages show sender name + avatar + timestamp
- Grouped by date separator

NOTES SCREEN:
- List of shared files (pdf, image, link, doc) with file type icon
- Upload FAB (file_picker for files, plus option for links)
- Owner sees Edit/Delete on their own files (3-dot per item)
- Non-owners see download only
- Link items open in browser
- Support dotted border drop zone for drag-and-drop upload on web

REQUESTS SCREEN (host only):
- List of pending join requests
- Each item: avatar + name + requested time + Approve (green) + Decline (red) buttons
