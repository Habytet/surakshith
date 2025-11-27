/**
 * Firebase Cloud Functions for Surakshith App
 * Automatic Push Notifications for Tasks and Reports
 *
 * This file contains all the Cloud Functions that automatically send
 * push notifications when tasks or reports are created/updated.
 *
 * NO MANUAL SENDING NEEDED - Everything is automatic!
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// ============================================
// HELPER FUNCTION: Get FCM tokens for users
// ============================================
/**
 * Gets FCM tokens for given user emails
 * @param {string[]} userEmails - Array of user email addresses
 * @returns {Promise<string[]>} Array of FCM tokens
 */
async function getFCMTokens(userEmails) {
  if (!userEmails || !Array.isArray(userEmails) || userEmails.length === 0) {
    console.log('⚠️ No user emails provided');
    return [];
  }

  // Use Promise.all for parallel queries (more efficient)
  const tokenPromises = userEmails.map(async (email) => {
    try {
      if (!email || typeof email !== 'string') {
        console.log(`⚠️ Invalid email: ${email}`);
        return [];
      }

      // Query users collection by email
      const userQuery = await admin.firestore()
        .collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!userQuery.empty) {
        const userData = userQuery.docs[0].data();

        // Check if user has FCM tokens
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
          console.log(`✅ Found ${userData.fcmTokens.length} token(s) for ${email}`);
          return userData.fcmTokens;
        } else {
          console.log(`⚠️ No FCM tokens for ${email}`);
          return [];
        }
      } else {
        console.log(`⚠️ User not found: ${email}`);
        return [];
      }
    } catch (error) {
      console.error(`❌ Error getting tokens for ${email}:`, error.message || error);
      return []; // Return empty array instead of failing completely
    }
  });

  // Wait for all queries to complete
  const tokenArrays = await Promise.all(tokenPromises);

  // Flatten the arrays and remove duplicates
  const tokens = [...new Set(tokenArrays.flat())];

  console.log(`📊 Total unique tokens found: ${tokens.length}`);
  return tokens;
}

// ============================================
// HELPER FUNCTION: Send push notification
// ============================================
/**
 * Sends push notification to multiple devices
 * @param {string[]} tokens - Array of FCM tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload
 * @returns {Promise} Firebase messaging response
 */
async function sendNotification(tokens, title, body, data) {
  if (!tokens || tokens.length === 0) {
    console.log('⚠️ No FCM tokens to send notification to');
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

    console.log(`✅ Successfully sent ${response.successCount} notification(s)`);

    if (response.failureCount > 0) {
      console.log(`❌ Failed to send ${response.failureCount} notification(s)`);

      // Log failed tokens for debugging
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Failed token ${idx}:`, resp.error);
        }
      });
    }

    return response;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return null;
  }
}

// ============================================
// SCENARIO 1: Task Created (Assigned)
// ============================================
/**
 * Triggers when a new task is created in Firestore
 * Sends notification to all assignees
 */
exports.onTaskCreated = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const taskId = context.params.taskId;

    // Validate task data
    if (!task) {
      console.error('❌ Task data is null or undefined');
      return null;
    }

    console.log('📝 ===== NEW TASK CREATED =====');
    console.log(`Task ID: ${taskId}`);
    console.log(`Task Title: ${task.title || 'Untitled'}`);
    console.log(`Assigned To: ${task.assignedTo && Array.isArray(task.assignedTo) ? task.assignedTo.join(', ') : 'None'}`);

    // Get assignee emails with validation
    const assigneeEmails = Array.isArray(task.assignedTo) ? task.assignedTo.filter(e => e && typeof e === 'string') : [];

    if (assigneeEmails.length === 0) {
      console.log('⚠️ No assignees for this task, skipping notification');
      return null;
    }

    // Get FCM tokens for assignees
    const tokens = await getFCMTokens(assigneeEmails);

    if (tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for assignees');
      return null;
    }

    // Determine priority emoji
    const priorityEmoji = task.priority === 'high' ? '🔴' :
                         task.priority === 'medium' ? '🟡' : '🟢';

    // Send notification
    console.log(`📤 Sending notification to ${tokens.length} device(s)...`);

    return sendNotification(
      tokens,
      `${priorityEmoji} New Task Assigned`,
      `You have been assigned: ${task.title}`,
      {
        taskId: taskId,
        type: 'task_assigned',
        priority: task.priority || 'medium',
      }
    );
  });

// ============================================
// SCENARIO 2-5: Task Updated (Status Changed)
// ============================================
/**
 * Triggers when a task is updated in Firestore
 * Handles: Task started, completed, approved, rejected
 */
exports.onTaskUpdated = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const taskId = context.params.taskId;

    console.log('🔄 ===== TASK UPDATED =====');
    console.log(`Task ID: ${taskId}`);
    console.log(`Status Change: ${before.status} → ${after.status}`);

    // Only send notification if status changed
    if (before.status === after.status) {
      console.log('⚠️ Status not changed, skipping notification');
      return null;
    }

    let title = '';
    let body = '';
    let notifyEmails = [];
    let notificationType = '';

    // Determine notification based on status change
    switch (after.status) {
      case 'inProgress':
        // SCENARIO: Staff started the task
        title = '▶️ Task Started';
        body = `${after.assignedTo && after.assignedTo.length > 0 ? after.assignedTo[0] : 'Someone'} started: ${after.title}`;
        notifyEmails = [after.createdBy];
        notificationType = 'task_started';
        console.log('📌 Notifying admin that task was started');
        break;

      case 'pendingReview':
        // SCENARIO 2: Staff submitted/completed task
        title = '✅ Task Submitted for Review';
        body = `Task "${after.title}" has been completed and is awaiting your review`;
        notifyEmails = [after.createdBy];
        notificationType = 'task_submitted';
        console.log('📌 Notifying admin that task is ready for review');
        break;

      case 'completed':
        // SCENARIO 3: Admin approved task
        title = '🎉 Task Approved!';
        body = `Great work! Your task "${after.title}" has been approved`;
        notifyEmails = after.assignedTo || [];
        notificationType = 'task_approved';
        console.log('📌 Notifying assignees that task was approved');
        break;

      case 'assigned':
        // SCENARIO 4: Admin rejected task (sent back to assigned)
        if (before.status === 'pendingReview') {
          title = '⚠️ Task Needs Revision';
          body = `Your task "${after.title}" needs changes`;

          // Add admin comments if available
          if (after.adminComments) {
            body += `. Reason: ${after.adminComments}`;
          }

          notifyEmails = after.assignedTo || [];
          notificationType = 'task_rejected';
          console.log('📌 Notifying assignees that task needs revision');
        } else {
          console.log('⚠️ Task moved to assigned but not from pendingReview, skipping');
          return null;
        }
        break;

      case 'incomplete':
        // Admin marked task as incomplete
        title = '❌ Task Marked Incomplete';
        body = `Task "${after.title}" has been marked as incomplete`;

        if (after.adminComments) {
          body += `. Reason: ${after.adminComments}`;
        }

        notifyEmails = after.assignedTo || [];
        notificationType = 'task_incomplete';
        console.log('📌 Notifying assignees that task was marked incomplete');
        break;

      default:
        console.log('⚠️ Unknown status change, skipping notification');
        return null;
    }

    // Check if we have emails to notify
    if (notifyEmails.length === 0) {
      console.log('⚠️ No emails to notify');
      return null;
    }

    // Get FCM tokens and send notification
    const tokens = await getFCMTokens(notifyEmails);

    if (tokens.length === 0) {
      console.log('⚠️ No FCM tokens found');
      return null;
    }

    console.log(`📤 Sending "${notificationType}" notification to ${tokens.length} device(s)...`);

    return sendNotification(tokens, title, body, {
      taskId: taskId,
      type: notificationType,
    });
  });

// ============================================
// SCENARIO 5: Report Created
// ============================================
/**
 * Triggers when a new report is created
 * Notifies all users belonging to that client
 */
exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    console.log('📋 ===== NEW REPORT CREATED =====');
    console.log(`Report ID: ${reportId}`);
    console.log(`Client ID: ${report.clientId}`);

    try {
      // Get all users for this client
      const usersQuery = await admin.firestore()
        .collection('users')
        .where('clientId', '==', report.clientId)
        .get();

      if (usersQuery.empty) {
        console.log('⚠️ No users found for this client');
        return null;
      }

      console.log(`✅ Found ${usersQuery.size} user(s) for this client`);

      const userEmails = usersQuery.docs.map(doc => doc.data().email);

      // Get client name for better notification message
      let clientName = 'Your company';
      try {
        const clientDoc = await admin.firestore()
          .collection('clients')
          .doc(report.clientId)
          .get();

        if (clientDoc.exists) {
          clientName = clientDoc.data().name;
          console.log(`✅ Client name: ${clientName}`);
        }
      } catch (error) {
        console.error('⚠️ Error getting client name:', error);
      }

      // Get FCM tokens
      const tokens = await getFCMTokens(userEmails);

      if (tokens.length === 0) {
        console.log('⚠️ No FCM tokens found for client users');
        return null;
      }

      // Send notification
      console.log(`📤 Sending report notification to ${tokens.length} device(s)...`);

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
      console.error('❌ Error in onReportCreated:', error);
      return null;
    }
  });

// ============================================
// SCENARIO 6: Check Overdue Tasks (Daily)
// ============================================
/**
 * Runs every day at 9:00 AM to check for overdue tasks
 * Sends reminder notifications to assignees
 */
exports.checkOverdueTasks = functions.pubsub
  .schedule('0 9 * * *')  // Every day at 9:00 AM
  .timeZone('Asia/Kolkata')  // Change this to your timezone
  .onRun(async (context) => {
    console.log('🔍 ===== CHECKING OVERDUE TASKS =====');
    console.log(`Time: ${new Date().toISOString()}`);

    const now = admin.firestore.Timestamp.now();

    try {
      // Get all tasks that are overdue and not completed
      const overdueTasksQuery = await admin.firestore()
        .collection('tasks')
        .where('dueDate', '<', now)
        .where('status', 'in', ['assigned', 'inProgress', 'pendingReview'])
        .get();

      if (overdueTasksQuery.empty) {
        console.log('✅ No overdue tasks found');
        return null;
      }

      console.log(`⚠️ Found ${overdueTasksQuery.size} overdue task(s)`);

      // Send notification for each overdue task
      const promises = overdueTasksQuery.docs.map(async (doc) => {
        const task = doc.data();
        const taskId = doc.id;
        const assigneeEmails = task.assignedTo || [];

        console.log(`📌 Overdue task: ${task.title}`);

        if (assigneeEmails.length === 0) {
          console.log('⚠️ No assignees for this task');
          return;
        }

        // Get FCM tokens
        const tokens = await getFCMTokens(assigneeEmails);

        if (tokens.length === 0) {
          console.log('⚠️ No FCM tokens for assignees');
          return;
        }

        // Calculate how many days overdue
        const dueDate = task.dueDate.toDate();
        const daysOverdue = Math.ceil((Date.now() - dueDate.getTime()) / (1000 * 60 * 60 * 24));

        // Send notification
        console.log(`📤 Sending overdue notification to ${tokens.length} device(s)...`);

        return sendNotification(
          tokens,
          '⏰ Task Overdue!',
          `Your task "${task.title}" is ${daysOverdue} day(s) overdue`,
          {
            taskId: taskId,
            type: 'task_overdue',
            daysOverdue: daysOverdue.toString(),
          }
        );
      });

      await Promise.all(promises);
      console.log('✅ Overdue task notifications sent');
      return null;
    } catch (error) {
      console.error('❌ Error checking overdue tasks:', error);
      return null;
    }
  });

// ============================================
// BONUS: Clean up old notifications (Weekly)
// ============================================
/**
 * Runs every Sunday at midnight to delete notifications older than 30 days
 * Keeps your Firestore database clean
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * 0')  // Every Sunday at midnight
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    console.log('🧹 ===== CLEANING UP OLD NOTIFICATIONS =====');

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const cutoffTime = thirtyDaysAgo.getTime();

    try {
      const oldNotifications = await admin.firestore()
        .collection('notifications')
        .where('createdAt', '<', cutoffTime)
        .get();

      if (oldNotifications.empty) {
        console.log('✅ No old notifications to delete');
        return null;
      }

      console.log(`🗑️ Found ${oldNotifications.size} old notification(s) to delete`);

      // Delete in batches
      const batch = admin.firestore().batch();
      oldNotifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`✅ Successfully deleted ${oldNotifications.size} old notification(s)`);
      return null;
    } catch (error) {
      console.error('❌ Error cleaning up notifications:', error);
      return null;
    }
  });

// ============================================
// INITIALIZATION
// ============================================
console.log('✅ Firebase Cloud Functions loaded successfully');
console.log('📱 Push notification functions are ready!');
console.log('');
console.log('Available functions:');
console.log('  - onTaskCreated: Notify assignees when task is created');
console.log('  - onTaskUpdated: Notify on status changes (started, submitted, approved, rejected)');
console.log('  - onReportCreated: Notify client users when report is created');
console.log('  - checkOverdueTasks: Daily check at 9 AM for overdue tasks');
console.log('  - cleanupOldNotifications: Weekly cleanup on Sunday midnight');
console.log('');
