# Build Session Manager (Create/Edit/Delete)

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

Create lib/features/session/screens/create_session_screen.dart
Create lib/features/session/screens/edit_session_screen.dart

FORM FIELDS (in order):
1. Visibility toggle — 3 options as segmented control:
   Public → sub-option: No Approval / Host Approval (radio group)
   Private → password input field appears below
2. Title — text input, required
3. Subject — dropdown with color swatch preview
4. Hashtags — chip input: user types tag + presses space/enter to add tag pill
   Tags shown as removable chips in #EDE9FE with #5186cd text
5. Short Description — multiline optional, 3 lines
6. Date — tapping opens date picker calendar modal (table_calendar package)
7. Time — Start time and End time pickers side by side
   Below them show computed duration e.g. '2 hrs 30 mins' in accent color
8. Location — text input
9. Participant Capacity — number stepper:
   Minus button [−] | number display | Plus button [+]
   Starts at 10, minimum 2
   Quick-add buttons: +5  +10  +15  +20 as small outline chips

BUTTONS:
- Create Session: Primary 48px full-width button
- Cancel: Outline 48px full-width button
- Edit screen additionally shows Delete button in red (#e53e3e) with confirm dialog

VALIDATION: show inline error below each field using #e53e3e text
