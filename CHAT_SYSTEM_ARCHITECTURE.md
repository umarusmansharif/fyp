# 🚀 Enhanced In-App Chat System Architecture

## 📊 **SYSTEM OVERVIEW**

A scalable, property-aware chat system for a real estate rental marketplace built with Flutter + Firebase Firestore.

---

## 🏗️ **FIRESTORE DATABASE STRUCTURE**

### **1. USERS Collection**
```
users/{userId}
├── name: string
├── email: string
├── role: "tenant" | "landlord"
├── phone: string
└── profileImage: string?
```

### **2. PROPERTIES Collection**
```
properties/{propertyId}
├── ownerId: string
├── title: string
├── location: string
├── latitude: double
├── longitude: double
├── price: double
├── images: string[]
└── status: "available" | "rented"
```

### **3. CHATS Collection (ENHANCED)**
```
chats/{chatId}
├── chatId: string                    // Unique ID: {tenantId}_{landlordId}_{propertyId}
├── tenantId: string                  // Tenant user ID
├── landlordId: string                // Landlord user ID
├── propertyId: string                // CRITICAL: Linked property
├── propertyTitle: string             // Embedded snapshot
├── propertyLocation: string          // Embedded snapshot
├── propertyPrice: double             // Embedded snapshot
├── propertyThumbnail: string         // First image URL
├── otherUserId: string               // Quick access to other participant
├── otherUserName: string             // Dynamic display name
├── lastMessage: string               // Last message preview
├── createdAt: timestamp
├── lastMessageAt: timestamp          // For sorting
├── unreadCount: int
└── isActive: boolean                 // Chat active status
```

### **4. MESSAGES Subcollection**
```
chats/{chatId}/messages/{messageId}
├── messageId: string
├── chatId: string
├── senderId: string
├── content: string
├── imageUrl: string?
├── timestamp: timestamp
├── isRead: boolean
└── type: "text" | "image" | "system"
```

---

## 🔑 **KEY FEATURES**

### **1. Property Context Awareness**
- ✅ Each chat is **tied to a specific property**
- ✅ Property metadata embedded in chat (no repeated joins)
- ✅ Both users see which property they're discussing
- ✅ Multiple chats allowed per landlord (one per property)

### **2. Dynamic Chat Naming**
**For Tenant:**
```
"Chat with {LandlordName} - {PropertyTitle}"
```

**For Landlord:**
```
"Chat with {TenantName} - {PropertyTitle}"
```

### **3. Smart Chat Creation**
```dart
// Before creating, check if chat exists
chatId = ChatModel.generateChatId(tenantId, landlordId, propertyId);

if (chat exists) {
  return existing chat;
} else {
  create new chat with property snapshot;
}
```

### **4. Unique Chat ID Generation**
```dart
static String generateChatId(String userId1, String userId2, String propertyId) {
  final sortedUsers = [userId1, userId2]..sort();
  return '${sortedUsers[0]}_${sortedUsers[1]}_$propertyId';
}
```
**Example:** `abc123_xyz789_property456`

---

## 📱 **CHAT LIST SCREEN**

### **Display Components:**
1. ✅ Property thumbnail image
2. ✅ Property title (bold)
3. ✅ Property location (subtitle)
4. ✅ Other user's profile picture
5. ✅ Other user's name
6. ✅ Last message preview
7. ✅ Time ago (e.g., "2h ago")
8. ✅ Unread message count badge

### **Sorting:**
- Ordered by `lastMessageAt` descending (most recent first)

---

## 💬 **CHAT DETAIL SCREEN**

### **Header:**
- ✅ Other user's avatar
- ✅ Dynamic chat name
- ✅ Property info (collapsible)

### **Messages:**
- ✅ Text messages (left/right alignment)
- ✅ Image messages (with tap to view)
- ✅ System messages (centered, gray)
- ✅ Timestamps
- ✅ Read receipts

### **Input:**
- ✅ Text input field
- ✅ Image upload button
- ✅ Send button with loading state

---

## 🔥 **FIRESTORE INDEXES REQUIRED**

### **1. Chats Collection Indexes**
```json
{
  "indexes": [
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tenantId", "order": "ASCENDING" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "landlordId", "order": "ASCENDING" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "propertyId", "order": "ASCENDING" }
      ]
    }
  ]
}
```

### **2. Messages Collection Indexes**
```json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "chatId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## ⚡ **PERFORMANCE OPTIMIZATIONS**

### **1. Property Snapshot Embedding**
- ❌ **Bad:** Fetch property every time chat loads
- ✅ **Good:** Store property data inside chat document

**Benefits:**
- Fewer reads
- Faster load times
- Reduced latency

### **2. Pagination for Messages**
```dart
// Load last 20 messages initially
QuerySnapshot snapshot = await _firestore
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .limit(20)
    .get();
```

### **3. Real-time Updates**
```dart
Stream<List<MessageModel>> messages = _firestore
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp')
    .snapshots()
    .map(...);
```

---

## 🎯 **CHAT CREATION FLOW**

### **From Property Detail Screen:**
```dart
1. User clicks "Chat with Owner" button
2. Check if user is authenticated
3. Get current user ID (tenantId)
4. Get property owner ID (landlordId)
5. Get property details (id, title, location, price, image)
6. Call: createOrGetChat(...)
7. Navigate to ChatDetailScreen with returned ChatModel
```

### **Example Implementation:**
```dart
Future<void> _startChat() async {
  final currentUser = _authService.getCurrentUser();
  if (currentUser == null) return;
  
  try {
    final chat = await _databaseService.createOrGetChat(
      tenantId: currentUser.uid,
      landlordId: widget.house.landlordId,
      propertyId: widget.house.houseId,
      propertyTitle: widget.house.title,
      propertyLocation: widget.house.location,
      propertyPrice: widget.house.price,
      propertyThumbnail: widget.house.images.first,
      otherUserName: 'Owner', // Fetch from user model
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chat: chat,
          currentUser: currentUser,
          otherUser: ownerUserModel,
        ),
      ),
    );
  } catch (e) {
    // Handle error
  }
}
```

---

## 🔒 **SECURITY CONSIDERATIONS**

### **Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chats: Only participants can access
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        (resource.data.tenantId == request.auth.uid || 
         resource.data.landlordId == request.auth.uid);
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Properties: Read-only for all authenticated users
    match /properties/{propertyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }
  }
}
```

---

## 📊 **SCALABILITY DESIGN**

### **✅ DO:**
- ✅ Use subcollections for messages
- ✅ Embed frequently accessed data (property snapshot)
- ✅ Use composite indexes for complex queries
- ✅ Limit message queries with pagination
- ✅ Use timestamps for sorting

### **❌ DON'T:**
- ❌ Create separate collection per user
- ❌ Store duplicate chat data
- ❌ Nest collections beyond 2 levels
- ❌ Fetch all messages at once
- ❌ Query without indexes

---

## 🚀 **FUTURE ENHANCEMENTS**

### **1. Typing Indicators**
```dart
chats/{chatId}/typing/{userId}
├── isTyping: boolean
└── lastUpdated: timestamp
```

### **2. Message Reactions**
```dart
messages/{messageId}/reactions/{userId}
├── emoji: string
└── timestamp: timestamp
```

### **3. Read Receipts**
```dart
messages/{messageId}/readBy/{userId}
└── readAt: timestamp
```

### **4. Analytics Tracking**
```dart
analytics/{chatId}
├── totalMessages: int
├── responseTime: double (average)
├── lastActive: timestamp
└── propertyViews: int
```

---

## 🎨 **UI/UX BEST PRACTICES**

### **1. Empty States**
- Show friendly message when no chats exist
- Provide CTA to browse properties

### **2. Loading States**
- Skeleton loaders for chat list
- CircularProgressIndicator for message send

### **3. Error Handling**
- Retry failed messages
- Show offline indicator
- Cache recent messages locally

### **4. Accessibility**
- Semantic labels for screen readers
- High contrast text
- Large tap targets

---

## 📝 **IMPLEMENTATION CHECKLIST**

- [x] Enhanced ChatModel with property context
- [x] Enhanced MessageModel with system messages
- [x] createOrGetChat with duplicate prevention
- [x] updateChatLastMessage for real-time preview
- [x] sendMessage with chat update
- [x] Unique chat ID generation
- [ ] Update ChatListScreen UI to show property info
- [ ] Update ChatDetailScreen header with property card
- [ ] Add pagination for messages
- [ ] Implement typing indicators
- [ ] Add message search functionality
- [ ] Create Firestore indexes
- [ ] Write security rules
- [ ] Add offline support
- [ ] Implement push notifications

---

## 🏆 **ARCHITECTURE SUMMARY**

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **Chat** | Communication | Property-aware, real-time messaging |
| **Property** | Context | Embedded snapshot in chat |
| **User** | Identity | Tenant + Landlord roles |
| **Message** | Content | Text, Image, System types |
| **Analytics** | Insights | Future: Track engagement |

---

## 📚 **RELATED FILES**

- `lib/models/chat_model.dart` - Chat data model
- `lib/models/message_model.dart` - Message data model
- `lib/services/database_service.dart` - Chat CRUD operations
- `lib/screens/chat_list_screen.dart` - Chat list UI
- `lib/screens/chat_detail_screen.dart` - Chat detail UI

---

**Last Updated:** April 2026  
**Version:** 2.0 (Property-Aware Chat System)
