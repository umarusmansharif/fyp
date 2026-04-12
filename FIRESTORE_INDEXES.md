# 🔥 Firestore Index Setup for RentHouse App

## Required Indexes

Your app needs the following Firestore composite indexes to work properly.

### **Index 1: Favorites Query**

**Error from log:**
```
The query requires an index. You can create it here:
https://console.firebase.google.com/v1/r/project/renthouse-d5d9e/firestore/indexes?create_composite=ClFwcm9qZWN0cy9yZW50aG91c2UtZDVkOWUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2Zhdm9yaXRlcy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoLCgdhZGRlZEF0EAIaDAoIX19uYW1lX18QAg
```

**How to Create:**

1. **Click the link above** (it will open Firebase Console)
2. **Sign in** to your Google account
3. **Select project:** `renthouse-d5d9e`
4. **Click "Create Index"** button
5. **Wait 5-10 minutes** for index to build

**Manual Setup (if link doesn't work):**

Go to Firebase Console → Firestore Database → Indexes tab → Create Index:

- **Collection ID:** `favorites`
- **Fields to index:**
  - `userId` - Ascending
  - `addedAt` - Descending
  - `__name__` - Descending (optional)
- **Query scope:** Collection

---

### **Index 2: Property Search (If needed)**

If you get errors for property search queries, create this index:

- **Collection ID:** `houses`
- **Fields to index:**
  - `status` - Ascending
  - `createdAt` - Descending
- **Query scope:** Collection

---

## How to Check Index Status

1. Go to: https://console.firebase.google.com/project/renthouse-d5d9e/firestore/indexes
2. Look at the "State" column
3. Wait until it shows "Enabled" (usually takes 2-10 minutes)

---

## Testing After Index Creation

After the index is created:
1. Restart your Flutter app
2. Try accessing Favorites again
3. The error should be gone!

---

## Common Issues

**Q: The link doesn't work**
A: Make sure you're logged into the Google account that owns the Firebase project

**Q: Index creation fails**
A: Make sure the field names match exactly (case-sensitive): `userId`, `addedAt`

**Q: Still getting errors after index is enabled**
A: Wait 2-3 minutes after index shows "Enabled", then restart the app
