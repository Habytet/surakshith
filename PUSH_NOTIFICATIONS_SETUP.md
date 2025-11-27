# Push Notifications Setup Guide

## Overview
Push notifications are implemented using Firebase Cloud Messaging (FCM). The Flutter app is already configured to receive notifications. To send push notifications, you need to set up a backend (Firebase Cloud Functions).

## What's Already Done ✅

1. **Flutter App Configuration**
   - ✅ FCM dependencies added (`firebase_messaging`, `flutter_local_notifications`)
   - ✅ FCM Service created (`lib/services/fcm_service.dart`)
   - ✅ Background message handler registered
   - ✅ Foreground notifications displayed
   - ✅ FCM tokens saved to Firestore (`users` collection, `fcmTokens` field)
   - ✅ Notification permissions requested (iOS/Android)

2. **Token Management**
   - ✅ FCM tokens saved when user logs in
   - ✅ FCM tokens removed when user logs out
   - ✅ Token refresh handling implemented

## What You Need to Do 🔧

### Option 1: Firebase Cloud Functions (Recommended)

Create Cloud Functions that listen to Firestore changes and send push notifications.

#### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### 2. Initialize Cloud Functions
```bash
cd /path/to/your/project
firebase init functions
```

#### 3. Create Cloud Function to Send Notifications

Edit `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when task is created
exports.onTaskCreated = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const taskId = context.params.taskId;

    // Get FCM tokens for assignees
    const assigneeEmails = task.assignedTo || [];
    const tokens = [];

    for (const email of assigneeEmails) {
      const userQuery = await admin.firestore()
        .collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!userQuery.empty) {
        const userData = userQuery.docs[0].data();
        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          tokens.push(...userData.fcmTokens);
        }
      }
    }

    if (tokens.length === 0) {
      console.log('No FCM tokens found for assignees');
      return null;
    }

    // Send notification
    const message = {
      notification: {
        title: 'New Task Assigned',
        body: `You have been assigned: ${task.title}`,
      },
      data: {
        taskId: taskId,
        type: 'task_assigned',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendMulticast(message);
      console.log(`Successfully sent ${response.successCount} messages`);
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

// Send notification when task status changes
exports.onTaskUpdated = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const taskId = context.params.taskId;

    // Only send notification if status changed
    if (before.status === after.status) {
      return null;
    }

    let title = '';
    let body = '';
    let notifyUserEmails = [];

    // Determine notification type
    if (after.status === 'completed' || after.status === 'pendingReview') {
      title = 'Task Completed';
      body = `${after.title} has been completed`;
      notifyUserEmails = [after.createdBy]; // Notify creator/admin
    } else if (after.status === 'assigned' && before.status === 'pendingReview') {
      title = 'Task Needs Revision';
      body = `${after.title} needs revision`;
      notifyUserEmails = after.assignedTo; // Notify assignees
    }

    if (notifyUserEmails.length === 0) {
      return null;
    }

    // Get FCM tokens
    const tokens = [];
    for (const email of notifyUserEmails) {
      const userQuery = await admin.firestore()
        .collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!userQuery.empty) {
        const userData = userQuery.docs[0].data();
        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          tokens.push(...userData.fcmTokens);
        }
      }
    }

    if (tokens.length === 0) {
      return null;
    }

    // Send notification
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        taskId: taskId,
        type: 'task_updated',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendMulticast(message);
      console.log(`Successfully sent ${response.successCount} messages`);
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });
```

#### 4. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### Option 2: Manual Testing with Firebase Console

1. Go to **Firebase Console** → Your Project → **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification title and body
4. Click **Send test message**
5. Enter the FCM token (check your app logs for the token)

### Option 3: Using Firebase Admin SDK from Your Backend

If you have your own backend server:

```javascript
const admin = require('firebase-admin');

// Initialize with service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
async function sendPushNotification(tokens, title, body, data) {
  const message = {
    notification: { title, body },
    data: data,
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log('Success:', response.successCount);
    console.log('Failures:', response.failureCount);
    return response;
  } catch (error) {
    console.error('Error:', error);
  }
}
```

## Android Configuration

Add to `android/app/src/main/AndroidManifest.xml` (inside `<application>` tag):

```xml
<!-- FCM -->
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Default notification channel -->
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@android:color/transparent" />
```

## iOS Configuration (if needed)

1. Enable Push Notifications in Xcode
2. Add APNs key in Firebase Console
3. Update `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Testing

1. **Get FCM Token**: Check app logs when you log in - you'll see "FCM Token: ..."
2. **Test with Firebase Console**: Use the token to send a test notification
3. **Test Foreground**: App open → Should show notification
4. **Test Background**: App minimized → Should receive notification
5. **Test Terminated**: App closed → Should receive notification when reopened

## Notification Data Structure

When sending notifications, include this data:

```json
{
  "notification": {
    "title": "Task Title",
    "body": "Task body"
  },
  "data": {
    "taskId": "task-id-here",
    "type": "task_assigned|task_updated|task_completed",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

## Firestore User Document Structure

FCM tokens are stored in the `users` collection:

```json
{
  "email": "user@example.com",
  "fcmTokens": ["token1", "token2"],
  "lastTokenUpdate": "2025-01-15T10:30:00Z"
}
```

## Troubleshooting

1. **No token received**: Check permissions, internet connection
2. **Notifications not received**: Verify google-services.json is up to date
3. **Token not saved**: Check Firestore rules allow writes to users collection
4. **iOS not working**: Verify APNs certificate is uploaded to Firebase

## Next Steps

1. Set up Cloud Functions (recommended)
2. Test notifications in all states (foreground/background/terminated)
3. Add notification analytics
4. Customize notification icons and sounds
5. Add notification action buttons (reply, complete, etc.)
