# Cloudinary Setup for Flutter App

## Configuration Requirements

### 1. Cloudinary Dashboard Setup

1. **Login to Cloudinary Dashboard** at cloudinary.com
2. **Navigate to Settings > Upload > Upload presets**
3. **Create a new upload preset** with these exact settings:

| Field | Value |
|-------|-------|
| Preset Name | `flutter_unsigned` |
| Signing Mode | `Unsigned` (Important!) |
| Folder | `renthouse_uploads` |
| Resource Type | `Image` |
| Access Mode | `Public` |

### 2. Flutter Integration

#### Upload Flow
```dart
// User selects image using image_picker
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
File imageFile = File(pickedFile!.path);

// Upload to Cloudinary with folder "renthouse_uploads"
final url = await CloudinaryService.uploadImageToCloudinary(imageFile);
```

#### Firestore Storage
After successful upload, Cloudinary returns `secure_url` which is saved to Firestore:
```dart
await FirebaseFirestore.instance.collection('houses').add({
  'title': title,
  'description': description,
  'imageUrl': cloudinaryUrl,  // The secure URL from Cloudinary
  'price': price,
  'location': location,
  'createdAt': FieldValue.serverTimestamp(),
});
```

### 3. Display Images

#### In Dashboard (Grid View)
- Uses `Image.network(imageUrl)` to display Cloudinary images
- Falls back to `Image.asset(defaultHouseImage)` if Cloudinary URL is empty

#### In Detail View
- Shows property image using `Image.network(imageUrl)`
- Has error handling to show default asset image if network image fails

### 4. Important Security Notes

- **Never expose API Secret in client Flutter code**
- Always use **unsigned** upload presets for client-side uploads
- The upload preset name in Flutter must match exactly what's configured in Cloudinary dashboard
- Folder name in request must match the preset folder configuration

### 5. Troubleshooting

**Error: "Upload preset not found"**
- Verify the preset name in Cloudinary dashboard matches the one in Flutter code
- Ensure the preset is configured as "Unsigned"
- Check that the preset is saved and active

**Error: "No URL return"**
- Check the detailed logs in console
- Verify internet connection
- Confirm file path is valid

### 6. Permissions

Make sure AndroidManifest.xml includes internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 7. Best Practices

- Always handle upload errors gracefully
- Show loading indicators during upload process
- Provide fallback images for network failures
- Validate file types and sizes before upload
- Use proper error handling for all async operations