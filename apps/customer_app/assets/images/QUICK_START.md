# 🚀 Quick Start: Rotating Background Images

## ✅ What's Done

Your login screen is now configured to rotate through 5 background photos every 2 seconds with smooth fade transitions!

**Code changes:**
- ✅ Timer added (rotates every 2 seconds)
- ✅ AnimatedSwitcher for smooth fade transitions
- ✅ 5 image slots configured
- ✅ Fallback gradient if images not loaded
- ✅ Blue overlay ensures text readability

---

## 📸 Next Step: Download 5 Images

You need to download 5 photos and place them here:
`C:\Users\arkoc\smartexit\apps\customer_app\assets\images\`

### Option 1: Use Recommended Images (5 minutes)

I've selected 4 great images for you. Just open these URLs and click "Download":

1. **Image 1**: [Friends with smartphone](https://www.pexels.com/photo/3764496/) → Save as `login_bg_1.jpg`
2. **Image 2**: [Couples in park](https://www.pexels.com/photo/3777727/) → Save as `login_bg_2.jpg`
3. **Image 3**: [Friends laughing](https://www.pexels.com/photo/9287491/) → Save as `login_bg_3.jpg`
4. **Image 4**: [Friends with drinks](https://www.pexels.com/photo/4143429/) → Save as `login_bg_4.jpg`
5. **Image 5**: [Browse here](https://www.pexels.com/search/friends%20laughing/) → Pick your favorite! Save as `login_bg_5.jpg`

**Download tips:**
- Click the green "Download" button on each photo
- Choose "Large (1920x1280)" or higher
- Rename each file to match the names above
- Move all files to: `apps/customer_app/assets/images/`

### Option 2: Choose Your Own (10 minutes)

Browse [Pexels - Friends Laughing](https://www.pexels.com/search/friends%20laughing/) and pick 5 images you love!

**What to look for:**
- Young people (18-25 years old)
- Laughing, happy, energetic vibes
- Diverse groups
- Bright, vibrant colors
- Landscape orientation

---

## 🎬 How It Works

Once you add the images:

```
Start (Image 1) → 2 sec fade → Image 2 → 2 sec fade → Image 3
→ 2 sec fade → Image 4 → 2 sec fade → Image 5 → 2 sec fade → Back to Image 1 (loop)
```

- **Transition**: Smooth 1-second fade between images
- **Cycle time**: 10 seconds total (5 images × 2 seconds each)
- **Overlay**: Semi-transparent blue gradient keeps text readable
- **Fallback**: If images fail to load, shows gradient background

---

## ▶️ Testing

After downloading the 5 images:

```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run -d chrome
```

Watch your login screen come alive with rotating backgrounds!

---

## 🎨 Visual Experience

**Without photos** (current state):
- Beautiful electric blue → lime green gradient
- Clean, modern, youthful vibe

**With photos** (after download):
- Dynamic rotating backgrounds of happy young people
- Blue overlay maintains brand colors
- Text remains perfectly readable
- Creates engaging, energetic first impression

---

## 📁 File Structure

```
apps/customer_app/assets/images/
├── login_bg_1.jpg  ← Download this
├── login_bg_2.jpg  ← Download this
├── login_bg_3.jpg  ← Download this
├── login_bg_4.jpg  ← Download this
├── login_bg_5.jpg  ← Download this
├── README.md
├── DOWNLOAD_GUIDE.md
├── QUICK_START.md (you are here!)
└── checklist.txt
```

---

## ❓ FAQ

**Q: What if I only download 3 images?**
A: The app will try to load all 5. Missing images will be skipped (gradient shows instead).

**Q: Can I use PNG instead of JPG?**
A: Yes! Just update the file extension in the code (line 38-42 of `customer_login_screen.dart`).

**Q: Can I change the rotation speed?**
A: Yes! Edit line 67 in `customer_login_screen.dart`: Change `Duration(seconds: 2)` to any duration you want.

**Q: Can I add more than 5 images?**
A: Yes! Add more filenames to the `_backgroundImages` list (line 38-44) and download those images.

---

## 🎯 Current Status

✅ Logo loading fixed (lowercase .png)
✅ Gradient background active
✅ Image rotation code implemented
⏳ **Ready for images!** Download the 5 photos to complete setup.

---

**Happy downloading! Your rotating background login screen awaits! 🎉**
