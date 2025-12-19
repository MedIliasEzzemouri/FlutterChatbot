# Logo Instructions

## How to Add Your Logo

1. **Place your logo file here:**
   - File name: `logo.png`
   - Location: `assets/images/logo.png`
   - Recommended size: 200x200 pixels or larger (square format works best)
   - Format: PNG with transparent background (preferred) or JPG

2. **The logo will be used in:**
   - Drawer header (user avatar) - displayed as a circular avatar
   - Login page (optional - can be updated)
   - Register page (optional - can be updated)

3. **After adding the logo:**
   - Run `flutter pub get` (if needed)
   - Hot restart the app (not just hot reload) to see the logo

## Current Usage

The logo is automatically loaded in:
- **Home Page Drawer**: Shows as user avatar in the drawer header
- Falls back to user's Firebase photo URL if logo not found
- Falls back to person icon if neither is available

## File Structure
```
assets/
  └── images/
      └── logo.png  ← Place your logo here
```

## Note
The app is already configured to use `assets/images/logo.png` in the code.
Just add your logo file and restart the app!

