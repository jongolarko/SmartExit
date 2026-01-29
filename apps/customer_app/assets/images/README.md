# Background Image for Login Screen

## Instructions

To add the background image of young people laughing to the login screen:

### Option 1: Quick Setup (Recommended)
1. Visit [Pexels - Friends Laughing](https://www.pexels.com/search/friends%20laughing/) or [Unsplash - Young People Having Fun](https://unsplash.com/s/photos/young-people-having-fun)
2. Search for images with these criteria:
   - **Subject**: Diverse group of young people (18-25 years) laughing/having fun
   - **Setting**: Casual, energetic environment (shopping, social setting)
   - **Colors**: Bright, vibrant colors (complement electric blue theme)
   - **Resolution**: At least 1920x1080 (landscape orientation)
   - **License**: Free for commercial use (both Pexels and Unsplash are free)

3. Download your chosen image
4. Save it as: `login_background.jpg` in this directory (`apps/customer_app/assets/images/`)
5. Open `apps/customer_app/lib/screens/customer/customer_login_screen.dart`
6. Find the `_buildBackground()` method (around line 239)
7. Uncomment the image loading code (lines marked with `/*` and `*/`)

### Option 2: Use Specific Recommended Images

Here are some suggested search terms that work well:
- "young friends laughing together"
- "gen z group happy casual"
- "diverse millennials celebrating"
- "young people smiling retail"
- "happy friends shopping"

### Code Changes Required

Once you've added `login_background.jpg` to this directory:

In `customer_login_screen.dart`, find this section in `_buildBackground()`:
```dart
// Optional: Background image (add your image to assets/images/login_background.jpg)
// Uncomment below once you add the image
/*
Positioned.fill(
  child: Image.asset(
    'assets/images/login_background.jpg',
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      // If image fails to load, show nothing (gradient will show)
      return const SizedBox.shrink();
    },
  ),
),
*/
```

**Uncomment** this section (remove `/*` and `*/`) to enable the background image.

### What Happens If No Image Is Added?

The login screen will show a beautiful gradient background using your brand colors (electric blue to lime green). The gradient provides an excellent fallback and maintains the youthful Gen Z aesthetic.

### Technical Details

- **Image format**: JPEG (`.jpg`) recommended for photos (smaller file size)
- **PNG** (`.png`) works too but will be larger
- **Gradient overlay**: A semi-transparent blue gradient is applied on top of the image to ensure text remains readable
- **Error handling**: If the image fails to load, the gradient background shows automatically
- **Performance**: Image is cached by Flutter for fast loading

### Testing

After adding the image:
```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run -d chrome
```

The background image should appear behind the login form with a blue gradient overlay for readability.

## Current Status

✅ **Logo loading fixed** - All logo files renamed to lowercase `.png`
✅ **Background structure added** - Stack layout with gradient ready
⏳ **Background image** - Ready for you to add (see instructions above)

The gradient background is currently active and looks great! Add the photo whenever you're ready to enhance it further.
