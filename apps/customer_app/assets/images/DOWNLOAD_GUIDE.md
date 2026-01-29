# Download 5 Background Images - Quick Guide

## What You Need
Download these 5 free images from Pexels and save them in this directory (`apps/customer_app/assets/images/`).

The app will automatically rotate through these images every 2 seconds with smooth fade transitions!

---

## Recommended Images (Copy these URLs to your browser)

### Image 1: `login_bg_1.jpg`
**Happy diverse friends laughing with smartphone**
- URL: https://www.pexels.com/photo/happy-diverse-friends-laughing-with-smartphone-at-home-3764496/
- Vibe: Indoor, casual, phone in hand, diverse group laughing
- Click "Download" → Select "Large (1920 x 1280)" or higher
- Save as: `login_bg_1.jpg`

### Image 2: `login_bg_2.jpg`
**Happy diverse couples laughing in park**
- URL: https://www.pexels.com/photo/happy-diverse-couples-laughing-in-park-3777727/
- Vibe: Outdoor, sunny park, couples, joyful atmosphere
- Click "Download" → Select "Large (1920 x 1280)" or higher
- Save as: `login_bg_2.jpg`

### Image 3: `login_bg_3.jpg`
**Group of friends laughing together**
- URL: https://www.pexels.com/photo/a-group-of-friends-laughing-together-9287491/
- Vibe: Group setting, authentic laughter, energetic
- Click "Download" → Select "Large (1920 x 1280)" or higher
- Save as: `login_bg_3.jpg`

### Image 4: `login_bg_4.jpg`
**Happy diverse people laughing with beverages**
- URL: https://www.pexels.com/photo/happy-diverse-people-laughing-while-drinking-takeaway-beverages-4143429/
- Vibe: Urban, drinks, social, modern Gen Z
- Click "Download" → Select "Large (1920 x 1280)" or higher
- Save as: `login_bg_4.jpg`

### Image 5: `login_bg_5.jpg`
**Your choice!**
- Browse: https://www.pexels.com/search/friends%20laughing/
- Find an image you love with young people laughing
- Look for: bright colors, energetic vibe, diverse group
- Click "Download" → Select "Large (1920 x 1280)" or higher
- Save as: `login_bg_5.jpg`

---

## Quick Download Steps

1. **Click each URL above** in your browser
2. **Click the green "Download" button** on each photo
3. **Select "Large" size** (1920x1280 or larger recommended)
4. **Rename each file** to match the names above:
   - First image → `login_bg_1.jpg`
   - Second image → `login_bg_2.jpg`
   - Third image → `login_bg_3.jpg`
   - Fourth image → `login_bg_4.jpg`
   - Fifth image → `login_bg_5.jpg`
5. **Move all 5 files** to: `C:\Users\arkoc\smartexit\apps\customer_app\assets\images\`

---

## Alternative: Browse and Choose Your Own

If you prefer different images:

1. Visit: https://www.pexels.com/search/friends%20laughing/
2. Filter by: Orientation → Landscape
3. Choose 5 images you love
4. Download as "Large" size
5. Rename to: `login_bg_1.jpg` through `login_bg_5.jpg`
6. Place in the `assets/images/` folder

**Search suggestions:**
- "young friends laughing"
- "gen z happy group"
- "diverse millennials celebrating"
- "young people shopping together"
- "friends having fun"

---

## Image Requirements

- **Format**: JPG (preferred for smaller size)
- **Resolution**: At least 1920x1080 (landscape)
- **Orientation**: Landscape (horizontal)
- **Colors**: Bright, vibrant (complements electric blue theme)
- **Subject**: Young diverse people (18-25), laughing/having fun
- **License**: All Pexels images are free for commercial use!

---

## What Happens After Download?

Once you place the 5 images in the folder:

1. Run: `flutter run -d chrome`
2. The login screen will display the first image
3. Every 2 seconds, it smoothly fades to the next image
4. After the 5th image, it loops back to the 1st
5. A blue gradient overlay ensures text remains readable

---

## Fallback Behavior

If images aren't downloaded yet, the app will show the beautiful gradient background (electric blue to lime green) until you add the photos. No errors!

---

## Current Status

✅ Code updated - Timer and AnimatedSwitcher implemented
✅ Smooth fade transitions every 2 seconds
✅ 5 image slots ready
⏳ **Next step: Download the 5 images using the URLs above**

Once images are added, restart the app to see them in action!
