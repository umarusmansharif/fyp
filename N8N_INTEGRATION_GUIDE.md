# 🤖 N8N AI Agent Integration Guide

## 📋 Overview

This guide explains how to configure the N8N AI Agent integration for the RentHouse Flutter application. The integration replaces the previous rule-based AI system with a powerful N8N-powered AI assistant.

---

## 🔧 Configuration Steps

### 1. Update N8N Webhook URL

**File:** `lib/services/n8n_ai_service.dart`

**Location:** Line 12
```dart
static const String _n8nWebhookUrl = 'YOUR_N8N_WEBHOOK_URL';
```

**Replace with your actual N8N webhook URL:**
```dart
static const String _n8nWebhookUrl = 'https://your-n8n-instance.com/webhook/renthouse-ai';
```

---

## 📡 Expected Request Format

The Flutter app sends POST requests with the following JSON payload:

```json
{
  "message": "User's message here",
  "userId": "firebase_user_uid",
  "userType": "tenant|landlord",
  "timestamp": "2026-05-12T18:37:00.000Z",
  "app": "renthouse",
  "context": {}
}
```

### Request Fields

| Field | Type | Description |
|-------|------|-------------|
| `message` | String | The user's question/message |
| `userId` | String | Firebase user UID for personalization |
| `userType` | String | User role: "tenant" or "landlord" |
| `timestamp` | String | ISO 8601 timestamp |
| `app` | String | Always "renthouse" |
| `context` | Object | Additional context (currently empty) |

---

## 📤 Expected Response Format

Your N8N workflow should return JSON with one of these formats:

### Format 1: Response field
```json
{
  "response": "AI response text here"
}
```

### Format 2: Message field
```json
{
  "message": "AI response text here"
}
```

### Format 3: Text field
```json
{
  "text": "AI response text here"
}
```

### Format 4: Plain string
```json
"AI response text here"
```

**HTTP Status:** `200 OK`

---

## 🎯 Role-Based Responses

The AI should provide different responses based on `userType`:

### For Tenants (`userType: "tenant"`):
- Property search assistance
- Rental application guidance
- Lease agreement explanations
- Safety tips for renters
- Property viewing scheduling
- Payment and deposit information

### For Landlords (`userType: "landlord"`):
- Property listing optimization
- Tenant screening guidance
- Rental pricing strategies
- Maintenance management tips
- Legal compliance advice
- Property marketing ideas

---

## ⚡ Error Handling

The Flutter app handles these error scenarios:

### HTTP Status Codes:
- `400` - "Invalid request. Please try again."
- `401` - "Authentication failed. Please contact support."
- `403` - "Access denied. Please contact support."
- `404` - "Service not available. Please try again later."
- `429` - "Too many requests. Please wait and try again."
- `500` - "Server error. Please try again later."
- `503` - "Service temporarily unavailable. Please try again later."

### Network Issues:
- **No internet:** "No internet connection. Please check your network and try again."
- **Timeout:** "Request timed out. Please try again."
- **Other errors:** "An unexpected error occurred. Please try again."

---

## 🔄 Retry Logic

The app implements automatic retry with exponential backoff:

- **Max retries:** 3
- **Retry delays:** 2s, 4s, 6s
- **Request timeout:** 30 seconds
- **Rate limiting:** Minimum 500ms between requests

---

## 🛡️ Security Features

### Request Tracking:
- Prevents duplicate requests
- Rate limiting to prevent spam
- Request deduplication by user ID + message hash

### Headers Sent:
```http
Content-Type: application/json
Accept: application/json
User-Agent: RentHouse-App/1.0
```

---

## 🧪 Testing the Integration

### 1. Configure Test Webhook
Use a tool like [webhook.site](https://webhook.site) to test request format:

```dart
static const String _n8nWebhookUrl = 'https://webhook.site/your-unique-id';
```

### 2. Check Configuration Status
The app provides a method to check configuration:

```dart
final aiService = AIChatbotService();
final status = aiService.getConfigurationStatus();
print(status);
// Output: {isConfigured: false, webhookUrl: YOUR_N8N_WEBHOOK_URL, ...}
```

### 3. Test Different User Types
- Test with tenant accounts
- Test with landlord accounts
- Verify role-appropriate responses

---

## 🚨 Fallback Behavior

If N8N is not configured or fails, the app falls back to:

1. **Basic predefined responses** for common questions
2. **Generic help messages** for other queries
3. **Error messages** for failed requests

This ensures the app remains functional even without N8N.

---

## 📱 User Experience

### Loading States:
- Typing indicator while waiting for response
- Loading spinner for suggested questions
- Disabled send button during requests

### Error Recovery:
- Automatic retry on network failures
- Clear error messages to users
- Graceful degradation to fallback responses

---

## 🔍 N8N Workflow Tips

### Recommended Setup:
1. **Webhook Trigger** - Receive requests from Flutter app
2. **AI/LLM Node** - Process user message with context
3. **Conditional Logic** - Route based on userType
4. **Response Node** - Format and return response

### Best Practices:
- Include user context in AI prompts
- Validate input before processing
- Handle edge cases gracefully
- Log requests for debugging
- Set appropriate timeouts

---

## 📞 Support

If you encounter issues:

1. **Check the webhook URL** is correctly configured
2. **Verify N8N workflow** is active and accessible
3. **Test with webhook tools** to validate request format
4. **Check network connectivity** in the app
5. **Review N8N execution logs** for errors

---

## 📝 Configuration Checklist

- [ ] Update `_n8nWebhookUrl` in `n8n_ai_service.dart`
- [ ] Test N8N workflow with sample requests
- [ ] Verify response format matches expected structure
- [ ] Test with both tenant and landlord accounts
- [ ] Check error handling scenarios
- [ ] Monitor request logs in N8N
- [ ] Validate rate limiting and retry logic

---

**Last Updated:** May 12, 2026  
**Version:** 1.0  
**Compatibility:** Flutter 3.6.1+, Dart 3.0+
