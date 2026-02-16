# Push Notifications for Friend Requests - Implementation Documentation

## Overview

This document describes the implementation of push notifications for friend requests in the Bolometro application using Firebase Cloud Messaging (FCM).

## Features Implemented

### 1. Notification Infrastructure

- **FCM Integration**: Added `firebase_messaging` package for push notification support
- **NotificationService**: Centralized service to manage FCM tokens and notifications
- **Permission Handling**: Requests user permission for notifications on app initialization
- **Token Management**: Automatic FCM token generation, storage, and updates

### 2. Notification Triggers

Push notifications are sent in the following scenarios:

1. **Friend Request Sent**: When a user sends a friend request, a notification is created for the recipient
2. **Friend Request Accepted**: When a user accepts a friend request, a notification is created for the sender

### 3. Notification Flow

```
User A sends friend request to User B
    ↓
FriendsService.enviarSolicitudAmistad()
    ↓
NotificationService.sendFriendRequestNotification()
    ↓
Notification document created in Firestore
    ↓
Cloud Functions (optional) sends push notification to User B's device
```

## Technical Implementation

### Architecture

#### NotificationService (`lib/services/notification_service.dart`)

The `NotificationService` is implemented as a singleton and provides:

- **Initialization**: `initialize()` - Requests permissions and sets up FCM
- **Token Management**:
  - `saveUserToken(userId)` - Stores FCM token in Firestore
  - `deleteUserToken(userId)` - Removes FCM token from Firestore
- **Notification Creation**:
  - `sendFriendRequestNotification()` - Creates notification for new friend request
  - `sendFriendRequestAcceptedNotification()` - Creates notification for accepted request
- **Message Handling**:
  - Handles foreground messages
  - Handles background message tap
  - Background message handler: `firebaseMessagingBackgroundHandler()`

#### Integration Points

1. **main.dart**:
   - Imports `firebase_messaging` package
   - Registers background message handler
   - Initializes NotificationService when user is authenticated

2. **FriendsService** (`lib/services/friends_service.dart`):
   - Triggers notifications after friend request operations
   - Line ~146: After creating friend request
   - Line ~243: After accepting friend request

3. **Firestore Rules** (`firestore.rules`):
   - Added rules for `notifications` subcollection
   - Users can read/update/delete their own notifications
   - Other users can create notifications (for friend requests)
   - Added comment clarifying FCM token storage in user documents

### Firestore Data Structure

```
users/{userId}/
  ├── fcmToken: string (FCM token for push notifications)
  ├── fcmTokenUpdatedAt: timestamp
  └── notifications/{notificationId}
      ├── type: string ('friend_request' | 'friend_request_accepted')
      ├── fromUserName: string (for friend_request)
      ├── acceptedByUserName: string (for friend_request_accepted)
      ├── requestId: string (for friend_request)
      ├── createdAt: timestamp
      └── read: boolean
```

### Android Configuration

**AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`):
- Added `INTERNET` permission (for FCM communication)
- Added `POST_NOTIFICATIONS` permission (required for Android 13+)

### Localization

Added notification strings in both Spanish and English:

**Spanish** (`lib/l10n/app_es.arb`):
- `notificationFriendRequest`: "{userName} te ha enviado una solicitud de amistad"
- `notificationFriendRequestAccepted`: "{userName} aceptó tu solicitud de amistad"
- `notificationFriendRequestTitle`: "Nueva solicitud de amistad"
- `notificationFriendRequestAcceptedTitle`: "Solicitud aceptada"

**English** (`lib/l10n/app_en.arb`):
- `notificationFriendRequest`: "{userName} has sent you a friend request"
- `notificationFriendRequestAccepted`: "{userName} accepted your friend request"
- `notificationFriendRequestTitle`: "New friend request"
- `notificationFriendRequestAcceptedTitle`: "Request accepted"

## Dependencies

### Added to pubspec.yaml
```yaml
firebase_messaging: ^14.9.4
```

## Usage

### For Developers

1. **Initialization**:
   The NotificationService is automatically initialized when a user logs in (see `_AuthWrapperState` in `main.dart`)

2. **Sending Notifications**:
   Notifications are automatically sent by the FriendsService when:
   - A friend request is created
   - A friend request is accepted

3. **Reading Notifications**:
   ```dart
   final notificationService = NotificationService();
   
   // Get unread count stream
   Stream<int> unreadCount = notificationService.getUnreadNotificationsCount(userId);
   
   // Mark all as read
   await notificationService.markNotificationsAsRead(userId);
   ```

## Important Notes

### Current Implementation

The current implementation creates notification documents in Firestore. These serve as:
1. In-app notifications that can be displayed to users
2. A trigger source for Firebase Cloud Functions (to be implemented)

### Cloud Functions (Recommended Next Step)

To send actual push notifications to user devices, you should implement Firebase Cloud Functions that:
1. Listen to new documents in the `notifications` collection
2. Read the recipient's `fcmToken` from their user document
3. Send the push notification using Firebase Admin SDK

Example Cloud Function (not included in this implementation):
```javascript
exports.sendFriendRequestNotification = functions.firestore
  .document('users/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const userId = context.params.userId;
    
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;
    
    if (!fcmToken) return;
    
    // Send notification
    const message = {
      notification: {
        title: notification.type === 'friend_request' 
          ? 'New friend request'
          : 'Request accepted',
        body: notification.type === 'friend_request'
          ? `${notification.fromUserName} has sent you a friend request`
          : `${notification.acceptedByUserName} accepted your friend request`
      },
      token: fcmToken
    };
    
    await admin.messaging().send(message);
  });
```

### iOS Configuration

For iOS, you'll need to:
1. Add `GoogleService-Info.plist` to the iOS project
2. Configure push notification capabilities in Xcode
3. Add required keys to `Info.plist`
4. Register for remote notifications

### Testing

To test notifications:
1. Run the app on a physical device (notifications don't work on iOS simulator)
2. Grant notification permissions when prompted
3. Send a friend request from another account
4. Check:
   - Notification document is created in Firestore
   - FCM token is saved in user document
   - If Cloud Functions are implemented, push notification should appear

## Security Considerations

- FCM tokens are stored securely in Firestore with appropriate access rules
- Only authenticated users can read/write their own FCM tokens
- Notification creation is restricted to valid friend request scenarios
- Background message handler is properly annotated with `@pragma('vm:entry-point')`

## Files Modified

- `pubspec.yaml` - Added firebase_messaging dependency
- `lib/services/notification_service.dart` - New service for notifications
- `lib/services/friends_service.dart` - Integrated notification triggers
- `lib/main.dart` - Added notification initialization
- `firestore.rules` - Added rules for notifications and FCM tokens
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions
- `lib/l10n/app_es.arb` - Added Spanish notification strings
- `lib/l10n/app_en.arb` - Added English notification strings

## Future Enhancements

1. **Cloud Functions**: Implement server-side notification sending
2. **Rich Notifications**: Add images, actions, and custom sounds
3. **Notification History**: UI to view notification history
4. **Notification Preferences**: Allow users to customize notification settings
5. **Badge Count**: Update app icon badge with unread notification count
6. **Deep Linking**: Navigate to specific screens when tapping notifications
7. **Group Notifications**: Group multiple friend requests together

---

**Implementation Date**: 2026-02-16
**Author**: GitHub Copilot Agent
