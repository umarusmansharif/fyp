# Troubleshooting Guide

## Common Issues and Solutions

### 1. Firestore Connection Issues
**Error**: `Unable to resolve host firestore.googleapis.com`

**Solutions**:
- Ensure your device has an active internet connection
- Check that the app has internet permission (it should be added in `android/app/src/main/AndroidManifest.xml` as `<uses-permission android:name="android.permission.INTERNET" />`)
- Verify your Firebase project is properly configured
- Check that your device's date and time are set correctly
- If using a VPN or proxy, try disabling it temporarily

### 2. Cloudinary Upload Issues
**Error**: `Bad Request` or `Invalid upload preset`

**Solutions**:
1. Ensure the upload preset `flutter_unsigned` exists in your Cloudinary dashboard:
   - Go to Cloudinary Dashboard → Settings → Upload
   - Under "Upload presets", click "Add upload preset"
   - Set name to `flutter_unsigned`
   - Set mode to "Unsigned"
   - Set folder to `renthouse_uploads`
   - Save the preset

2. Verify your Cloudinary credentials in `lib/services/cloudinary_service.dart`:
   - Cloud name: `dg7f5ssue`
   - Upload preset: `flutter_unsigned`

### 3. Layout Overflow Issues
**Error**: `RenderFlex overflowed by X pixels`

**Solutions**:
- The HouseCard widget has been optimized with smaller text sizes and constraints
- The grid aspect ratios have been adjusted in dashboard and profile screens
- Description text is now limited to 2 lines with ellipsis

### 4. Building the App
If you encounter build issues:

1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

2. Make sure you have the latest dependencies:
   ```bash
   flutter pub upgrade
   ```

### 5. Firebase Configuration
If the app doesn't connect to Firebase:

1. Verify `lib/firebase_options.dart` exists and is properly configured
2. Make sure `google-services.json` is in the correct location (`android/app/google-services.json`)
3. Check that your device has Google Play Services installed

### 6. Image Upload Process
The image upload flow is:
1. User selects image using ImagePicker
2. Image is uploaded to Cloudinary using unsigned preset
3. Cloudinary returns secure URL
4. URL is saved to Firestore along with other house data
5. Dashboard displays images using Image.network()

### 7. Testing the App
To test the image upload functionality:
1. Create the Cloudinary upload preset as described above
2. Ensure internet connectivity
3. Use a real device or properly configured emulator
4. Check the debug console for any error messages

### 8. Debugging Tips
- Enable verbose logging during development to see detailed error messages
- Check the Flutter console for specific error details
- Verify that all required indexes are created in Firestore
- Ensure all permissions are granted on the device