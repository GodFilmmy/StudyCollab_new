# Build Authentication Screens

Read lib/core/theme/app_theme.dart and lib/models/models.dart first.

Create these files following the Study Collab design system strictly:

1. lib/features/auth/screens/splash_screen.dart
   - Full screen with #5186CD accent background
   - Study Collab logo (bookmark icon) + app name in white Poppins Bold 40px
   - Fade + slide up animation using flutter_animate
   - After 2.5s navigate to login_screen

2. lib/features/auth/screens/login_screen.dart
   - Background: #fafcff
   - Top section: Study Collab logo + Headline 1 greeting (Welcome Back)
   - University email input with validation (must end in .edu or .ac.th or university domain)
   - Password input with show/hide toggle
   - Primary button (48px, #5186cd) labeled Sign In
   - Outline button for Sign Up
   - Error states: red border + error message below field (#e53e3e)
   - Disabled state: #b0c7e8 fill

3. lib/features/auth/screens/signup_screen.dart
   - Name field, University Email, Password, Confirm Password
   - University / Major text fields
   - Avatar upload (image_picker) with circle preview
   - Same button and input styling as login
