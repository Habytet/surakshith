# Complete Firebase Cloud Functions Setup for Automatic Push Notifications

## Overview
This setup will **automatically send push notifications** when:
- Task is assigned → Notify assignees
- Task is completed/submitted → Notify admin/auditor
- Task is approved → Notify assignee
- Task is rejected → Notify assignee
- Report is created → Notify client users

**NO MANUAL SENDING REQUIRED** - Everything is automatic!

---

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

---

## Step 2: Initialize Cloud Functions

```bash
cd /Users/haarisbasheer/AndroidStudioProjects/surakshith
firebase init functions
```

Select:
- Use existing project → Select your Surakshith project
- Language: **JavaScript** (easier) or TypeScript
- ESLint: Yes
- Install dependencies: Yes

---

## Step 3: Create Cloud Functions

Edit `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ============================================
// HELPER FUNCTION: Get FCM tokens for users
// ============================================
async function getFCMTokens(userEmails) {
  const tokens = [];

  for (const email of userEmails) {
    try {
      // Query users by email
      const userQuery = await admin.firestore()
        .collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!userQuery.empty) {
        const userData = userQuery.docs[0].data();
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
          tokens.push(...userData.fcmTokens);
        }
      }
    } catch (error) {
      console.error(`Error getting tokens for ${email}:`, error);
    }
  }

  return tokens;
}

// ============================================
// HELPER FUNCTION: Send notification
// ============================================
async function sendNotification(tokens, title, body, data) {
  if (tokens.length === 0) {
    console.log('No FCM tokens to send notification to');
    return null;
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ Sent ${response.successCount} notifications`);
    console.log(`❌ Failed ${response.failureCount} notifications`);

    // Log failed tokens
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
        }
      });
    }

    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    return null;
  }
}

// ============================================
// TRIGGER: When a task is CREATED
// ============================================
exports.onTaskCreated = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const taskId = context.params.taskId;

    console.log(`📝 New task created: ${task.title}`);

    // Get assignee emails
    const assigneeEmails = task.assignedTo || [];
    if (assigneeEmails.length === 0) {
      console.log('No assignees for this task');
      return null;
    }

    // Get FCM tokens
    const tokens = await getFCMTokens(assigneeEmails);

    // Determine priority emoji
    const priorityEmoji = task.priority === 'high' ? '🔴' :
                         task.priority === 'medium' ? '🟡' : '🟢';

    // Send notification
    return sendNotification(
      tokens,
      `${priorityEmoji} New Task Assigned`,
      `You have been assigned: ${task.title}`,
      {
        taskId: taskId,
        type: 'task_assigned',
        priority: task.priority,
      }
    );
  });

// ============================================
// TRIGGER: When a task is UPDATED
// ============================================
exports.onTaskUpdated = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const taskId = context.params.taskId;

    // Check what changed
    const statusChanged = before.status !== after.status;

    if (!statusChanged) {
      console.log('Status not changed, skipping notification');
      return null;
    }

    console.log(`🔄 Task status changed: ${before.status} → ${after.status}`);

    let title = '';
    let body = '';
    let notifyEmails = [];
    let notificationType = '';

    // Determine notification based on status change
    switch (after.status) {
      case 'inProgress':
        // Staff started the task - notify admin/creator
        title = '▶️ Task Started';
        body = `${after.assignedTo[0]} started: ${after.title}`;
        notifyEmails = [after.createdBy];
        notificationType = 'task_started';
        break;

      case 'pendingReview':
        // Staff submitted task - notify admin/auditor
        title = '✅ Task Submitted for Review';
        body = `${after.assignedTo[0]} completed: ${after.title}`;
        notifyEmails = [after.createdBy];
        notificationType = 'task_submitted';
        break;

      case 'completed':
        // Admin approved task - notify assignees
        title = '🎉 Task Approved!';
        body = `Your task "${after.title}" has been approved`;
        notifyEmails = after.assignedTo;
        notificationType = 'task_approved';
        break;

      case 'assigned':
        // Only notify if coming from pendingReview (rejection)
        if (before.status === 'pendingReview') {
          title = '⚠️ Task Needs Revision';
          body = `Your task "${after.title}" needs changes`;
          if (after.adminComments) {
            body += `. Reason: ${after.adminComments}`;
          }
          notifyEmails = after.assignedTo;
          notificationType = 'task_rejected';
        }
        break;

      case 'incomplete':
        // Admin marked incomplete - notify assignees
        title = '❌ Task Marked Incomplete';
        body = `Task "${after.title}" marked as incomplete`;
        if (after.adminComments) {
          body += `. Reason: ${after.adminComments}`;
        }
        notifyEmails = after.assignedTo;
        notificationType = 'task_incomplete';
        break;

      default:
        return null;
    }

    if (notifyEmails.length === 0) {
      return null;
    }

    // Get FCM tokens and send
    const tokens = await getFCMTokens(notifyEmails);
    return sendNotification(tokens, title, body, {
      taskId: taskId,
      type: notificationType,
    });
  });

// ============================================
// TRIGGER: When a report is CREATED
// ============================================
exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    console.log(`📋 New report created for client: ${report.clientId}`);

    try {
      // Get all users for this client
      const usersQuery = await admin.firestore()
        .collection('users')
        .where('clientId', '==', report.clientId)
        .get();

      if (usersQuery.empty) {
        console.log('No users found for this client');
        return null;
      }

      const userEmails = usersQuery.docs.map(doc => doc.data().email);

      // Get client name
      let clientName = 'Your company';
      try {
        const clientDoc = await admin.firestore()
          .collection('clients')
          .doc(report.clientId)
          .get();

        if (clientDoc.exists) {
          clientName = clientDoc.data().name;
        }
      } catch (error) {
        console.error('Error getting client name:', error);
      }

      // Get FCM tokens
      const tokens = await getFCMTokens(userEmails);

      // Send notification
      return sendNotification(
        tokens,
        '📋 New Audit Report Available',
        `A new audit report has been created for ${clientName}`,
        {
          reportId: reportId,
          type: 'report_created',
          clientId: report.clientId,
        }
      );
    } catch (error) {
      console.error('Error in onReportCreated:', error);
      return null;
    }
  });

// ============================================
// TRIGGER: When a task becomes OVERDUE
// ============================================
// This runs daily at 9 AM to check for overdue tasks
exports.checkOverdueTasks = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Kolkata') // Change to your timezone
  .onRun(async (context) => {
    console.log('🔍 Checking for overdue tasks...');

    const now = admin.firestore.Timestamp.now();

    try {
      // Get all overdue tasks that are not completed
      const overdueTasksQuery = await admin.firestore()
        .collection('tasks')
        .where('dueDate', '<', now)
        .where('status', 'in', ['assigned', 'inProgress', 'pendingReview'])
        .get();

      if (overdueTasksQuery.empty) {
        console.log('No overdue tasks found');
        return null;
      }

      console.log(`Found ${overdueTasksQuery.size} overdue tasks`);

      // Send notification for each overdue task
      const promises = overdueTasksQuery.docs.map(async (doc) => {
        const task = doc.data();
        const assigneeEmails = task.assignedTo || [];

        if (assigneeEmails.length === 0) return;

        const tokens = await getFCMTokens(assigneeEmails);

        return sendNotification(
          tokens,
          '⏰ Task Overdue!',
          `Your task "${task.title}" is overdue`,
          {
            taskId: doc.id,
            type: 'task_overdue',
          }
        );
      });

      await Promise.all(promises);
      console.log('✅ Overdue notifications sent');
      return null;
    } catch (error) {
      console.error('Error checking overdue tasks:', error);
      return null;
    }
  });

// ============================================
// OPTIONAL: Clean up old notifications
// ============================================
// Runs every Sunday at midnight to delete old notifications
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * 0')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    console.log('🧹 Cleaning up old notifications...');

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const oldNotifications = await admin.firestore()
        .collection('notifications')
        .where('createdAt', '<', thirtyDaysAgo.getTime())
        .get();

      if (oldNotifications.empty) {
        console.log('No old notifications to delete');
        return null;
      }

      const batch = admin.firestore().batch();
      oldNotifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`✅ Deleted ${oldNotifications.size} old notifications`);
      return null;
    } catch (error) {
      console.error('Error cleaning up notifications:', error);
      return null;
    }
  });

// ============================================
// EXPORT ALL FUNCTIONS
// ============================================
console.log('✅ Cloud Functions loaded successfully');
```

---

## Step 4: Install Dependencies

```bash
cd functions
npm install firebase-admin firebase-functions
```

---

## Step 5: Deploy to Firebase

```bash
firebase deploy --only functions
```

This will deploy all functions. You'll see output like:
```
✔ functions[onTaskCreated]: Successful create operation.
✔ functions[onTaskUpdated]: Successful create operation.
✔ functions[onReportCreated]: Successful create operation.
✔ functions[checkOverdueTasks]: Successful create operation.
```

---

## How It Works (No Manual Sending!)

### Example Flow:

1. **Admin creates task in app** → Firestore: `tasks/{taskId}` created
2. **Cloud Function triggers automatically** → `onTaskCreated` runs
3. **Function gets assignee's FCM token** → Queries Firestore users collection
4. **Function sends push notification** → Uses Firebase Admin SDK
5. **Assignee's phone receives notification** → Shows in notification tray
6. **Assignee taps notification** → App opens TaskDetailScreen

### All Scenarios Covered:

| App Action | Cloud Function | Who Gets Notified |
|------------|----------------|-------------------|
| Task assigned | `onTaskCreated` | Assignees |
| Task started | `onTaskUpdated` | Admin/Creator |
| Task submitted | `onTaskUpdated` | Admin/Auditor |
| Task approved | `onTaskUpdated` | Assignees |
| Task rejected | `onTaskUpdated` | Assignees |
| Report created | `onReportCreated` | All client users |
| Task overdue | `checkOverdueTasks` (daily) | Assignees |

---

## Testing

1. **Deploy functions** (as shown above)
2. **Open your app** and login
3. **Create a task** and assign it to someone
4. **Check the assignee's phone** → Should receive notification!
5. **Check Firebase Console** → Functions → Logs to see execution

---

## Monitoring

Firebase Console → Functions → Logs shows:
- ✅ "Sent 2 notifications"
- 📝 "New task created: Clean kitchen"
- 🔄 "Task status changed: assigned → completed"

---

## Cost

Firebase Cloud Functions:
- **Free tier**: 2M invocations/month
- Your app will use ~10-50 invocations per day
- **Cost**: $0 (well within free tier)

---

## Troubleshooting

**No notifications received?**
1. Check Firebase Console → Functions → Logs
2. Verify FCM tokens are saved in Firestore (users collection)
3. Test with Firebase Console first (manual test)

**Function errors?**
- Check logs: `firebase functions:log`
- Common issue: Firestore rules blocking reads

---

## Summary

✅ **100% Automatic** - No manual sending needed
✅ **Real-time** - Notifications sent within seconds
✅ **Reliable** - Firebase handles delivery
✅ **Scalable** - Works for 1 user or 10,000 users

Your app will automatically send push notifications whenever tasks or reports are created/updated!
