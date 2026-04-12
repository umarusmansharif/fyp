# Android Studio Crash Fix - Step by Step Guide

## ✅ ISSUES FIXED:

### 1. **Firebase Initialization** (CRITICAL)
- **Problem**: Firebase.initializeApp() was called without platform-specific options
- **Fix**: Added `DefaultFirebaseOptions.currentPlatform` with proper error handling
- **File**: `lib/main.dart`

### 2. **Gradle Memory Too Low** (CRITICAL)
- **Problem**: 1536MB RAM was insufficient, causing Android Studio to crash
- **Fix**: Increased to 4096MB with optimized caching
- **File**: `android/gradle.properties`

### 3. **Missing Android Permissions**
- **Problem**: Image picker requires camera and storage permissions
- **Fix**: Added CAMERA, READ/WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES
- **File**: `android/app/src/main/AndroidManifest.xml`

---

## 🚀 HOW TO RUN THE APP:

### **Step 1: Clean Everything**
```bash
flutter clean
flutter pub get
```

### **Step 2: Connect Your Android Device**
1. Enable **Developer Options** on your vivo phone
2. Enable **USB Debugging**
3. Connect via USB
4. Verify connection:
```bash
adb devices
```

### **Step 3: Run in Android Studio**
1. Open Android Studio
2. Open the project at `f:\renthouse`
3. Wait for Gradle sync to complete (may take 2-3 minutes)
4. Select your device from the device dropdown
5. Click **Run** (green play button) or press `Shift+F10`

### **Alternative: Run via Command Line**
```bash
flutter run
```

---

## 🔧 IF ANDROID STUDIO STILL CRASHES:

### **Option 1: Increase Android Studio Memory**
1. Open Android Studio
2. Go to **Help** → **Change Memory Settings**
3. Set to **2048 MB** or **3072 MB**
4. Restart Android Studio

### **Option 2: Invalidate Caches**
1. **File** → **Invalidate Caches**
2. Check "Clear file system cache"
3. Click **Invalidate and Restart**

### **Option 3: Use VS Code Instead**
VS Code is lighter and won't crash:
1. Open VS Code
2. Install Flutter & Dart extensions
3. Open the project
4. Press `F5` to run

### **Option 4: Run Directly via Command Line**
```bash
flutter run -d <your-device-id>
```

---

## 📱 TROUBLESHOOTING:

### **No Device Detected**
```bash
# Check USB connection
adb devices

# Restart adb
adb kill-server
adb start-server

# Check USB mode (set to "File Transfer" or "MTP")
```

### **Gradle Sync Fails**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### **Firebase Connection Issues**
- Verify `google-services.json` exists at `android/app/google-services.json` ✅
- Verify `firebase_options.dart` exists at `lib/firebase_options.dart` ✅
- Check internet connection

---

## 📊 CURRENT CONFIGURATION:

| Setting | Value |
|---------|-------|
| Flutter SDK | 3.27.3 |
| Dart SDK | 3.6.1 |
| Gradle Memory | 4096 MB (increased from 1536) |
| Kotlin Memory | 2048 MB (increased from 512) |
| Android Gradle Plugin | 8.9.1 |
| Kotlin Version | 2.1.0 |
| Firebase | Properly configured ✅ |

---

## ⚠️ IMPORTANT NOTES:

1. **First build may take 5-10 minutes** - This is normal
2. **Subsequent builds will be faster** thanks to caching
3. **Keep your device connected** during debugging
4. **Android Studio may use 2-4 GB RAM** - This is expected

---

## 🎯 RECOMMENDED WORKFLOW:

For **development** (fastest):
```bash
flutter run --hot
```

For **testing**:
```bash
flutter run --profile
```

For **release**:
```bash
flutter build apk --release
```

---

## ✨ WHAT WAS WRONG:

The main crash was caused by:
1. ❌ Firebase initialization without proper options
2. ❌ Insufficient Gradle memory (1536MB → caused OutOfMemoryError)
3. ❌ Missing Android permissions for image features

All three issues are now **FIXED** ✅
