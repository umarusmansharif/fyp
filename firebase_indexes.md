# Firestore Composite Indexes Setup

This document outlines the required composite indexes needed for the RentHouse app to function properly.

## Required Composite Indexes

The following composite indexes are required to support the queries in the application:

### 1. Houses Collection
- **Index Name**: `houses_landlordId_createdAt`
- **Fields**: 
  - `landlordId` (ASC)
  - `createdAt` (DESC)
- **Purpose**: Used in "My Listings" section to show houses by landlord with newest first
- **Query**: `getHousesByLandlord()` in DatabaseService

### 2. Orders Collection
- **Index Name**: `orders_landlordId_createdAt`
- **Fields**:
  - `landlordId` (ASC)
  - `createdAt` (DESC)
- **Purpose**: Used in "Received Requests" section to show orders by landlord with newest first
- **Query**: `getOrdersForLandlord()` in DatabaseService

### 3. Orders Collection
- **Index Name**: `orders_tenantId_createdAt`
- **Fields**:
  - `tenantId` (ASC)
  - `createdAt` (DESC)
- **Purpose**: Used in "My Requests" section to show orders by tenant with newest first
- **Query**: `getOrdersForTenant()` in DatabaseService

## How to Create Indexes

### Option 1: Using Firebase Console
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Go to "Indexes" tab
4. Click "Create Index"
5. Select the collection (e.g., "houses" or "orders")
6. Add the required fields in the specified order and direction
7. Click "Create Index"

### Option 2: Using Firebase CLI (if you have firebase-tools installed)
1. Create or update `firestore.indexes.json` in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "houses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "landlordId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "landlordId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "tenantId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

2. Deploy the indexes:
```bash
firebase deploy --only firestore:indexes
```

## Index Build Time
- Composite indexes typically take 1-5 minutes to build
- Queries will fail until the index is fully built
- You'll see a progress indicator in the Firebase Console

## Verification
After creating the indexes:
1. Wait for the index to finish building (check Firebase Console)
2. Test the "My Listings" and "Received Requests" sections in the app
3. The Firestore error should disappear and data should load properly

## Troubleshooting
- If you still see the error, verify the index is fully built
- Check that field names match exactly (case-sensitive)
- Ensure the field order and direction match the requirements above
- Clear the app cache and restart to refresh the connection