# Firestore Configuration for Task Management System

This document contains the required Firestore indexes and security rules for the Task Management System (Phase 1 - Data Foundation).

## 📊 Firestore Indexes

### Required Composite Indexes

You need to create these indexes in Firebase Console → Firestore Database → Indexes:

#### 1. Tasks Collection - Client + Status + Due Date
```
Collection: tasks
Fields:
  - clientId (Ascending)
  - status (Ascending)
  - dueDate (Descending)
```

#### 2. Tasks Collection - Assignee + Status + Due Date
```
Collection: tasks
Fields:
  - assignedTo (Array)
  - status (Ascending)
  - dueDate (Ascending)
```

#### 3. Tasks Collection - Source + Created Date
```
Collection: tasks
Fields:
  - source (Ascending)
  - createdAt (Descending)
```

#### 4. Tasks Collection - Status + Priority
```
Collection: tasks
Fields:
  - status (Ascending)
  - priority (Descending)
```

#### 5. Tasks Collection - Client + Source + Status
```
Collection: tasks
Fields:
  - clientId (Ascending)
  - source (Ascending)
  - status (Ascending)
```

#### 6. Tasks Collection - Type + Created Date
```
Collection: tasks
Fields:
  - type (Ascending)
  - createdAt (Descending)
```

#### 7. Notifications Collection - User + Created Date
```
Collection: notifications
Fields:
  - userId (Ascending)
  - createdAt (Descending)
```

#### 8. Notifications Collection - User + Read Status + Created Date
```
Collection: notifications
Fields:
  - userId (Ascending)
  - isRead (Ascending)
  - createdAt (Descending)
```

#### 9. Notifications Collection - User + Type + Created Date
```
Collection: notifications
Fields:
  - userId (Ascending)
  - type (Ascending)
  - createdAt (Descending)
```

#### 10. Users Collection - Role + Active Status
```
Collection: users
Fields:
  - role (Ascending)
  - isActive (Ascending)
```

#### 11. Users Collection - Client + Role + Active Status
```
Collection: users
Fields:
  - clientId (Ascending)
  - role (Ascending)
  - isActive (Ascending)
```

### How to Create Indexes

**Option 1: Firebase Console (Manual)**
1. Go to Firebase Console → Your Project
2. Navigate to Firestore Database → Indexes
3. Click "+ Create Index"
4. Select collection and add fields as specified above
5. Click "Create"

**Option 2: Firebase CLI (Automated)**
Save the following to `firestore.indexes.json` in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "dueDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "assignedTo", "arrayConfig": "CONTAINS" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "dueDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "source", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "priority", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "source", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy with:
```bash
firebase deploy --only firestore:indexes
```

---

## 🔒 Firestore Security Rules

Replace your current Firestore rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Get user data
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    // Check if user is an auditor
    function isAuditor() {
      return isAuthenticated() && getUserData().role == 'auditor';
    }

    // Check if user belongs to a specific client
    function isClientUser(clientId) {
      return isAuthenticated() &&
             getUserData().clientId == clientId &&
             getUserData().isActive == true;
    }

    // Check if user is a client admin for specific client
    function isClientAdmin(clientId) {
      return isAuthenticated() &&
             getUserData().clientId == clientId &&
             getUserData().role == 'clientAdmin' &&
             getUserData().isActive == true;
    }

    // Check if user is a client staff for specific client
    function isClientStaff(clientId) {
      return isAuthenticated() &&
             getUserData().clientId == clientId &&
             getUserData().role == 'clientStaff' &&
             getUserData().isActive == true;
    }

    // Check if user is assigned to a task
    function isAssignedTo(taskData) {
      return isAuthenticated() &&
             request.auth.token.email in taskData.assignedTo;
    }

    // Check if user owns a resource (created it)
    function isOwner(resourceData) {
      return isAuthenticated() &&
             request.auth.token.email == resourceData.createdBy;
    }

    // ============================================
    // USERS COLLECTION
    // ============================================

    match /users/{userId} {
      // Anyone authenticated can read all users (for task assignment)
      allow read: if isAuthenticated();

      // Only auditors can create/update/delete users
      allow create, update, delete: if isAuditor();
    }

    // ============================================
    // TASKS COLLECTION
    // ============================================

    match /tasks/{taskId} {
      // AUDITORS: Full access to all tasks
      allow read, create, delete: if isAuditor();
      allow update: if isAuditor();

      // CLIENT ADMINS: Read tasks for their client
      allow read: if isClientAdmin(resource.data.clientId);

      // CLIENT STAFF: Read tasks assigned to them
      allow read: if isClientStaff(resource.data.clientId) &&
                     isAssignedTo(resource.data);

      // CLIENT STAFF: Update only their assigned tasks (limited fields)
      allow update: if isClientStaff(resource.data.clientId) &&
                       isAssignedTo(resource.data) &&
                       // Can only update specific fields
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly([
                           'status',
                           'staffComments',
                           'staffImages',
                           'complianceStatus',
                           'startedAt',
                           'completedAt'
                         ]);
    }

    // ============================================
    // TASK TEMPLATES (for repetitive tasks)
    // ============================================

    match /taskTemplates/{templateId} {
      // Only auditors can manage templates
      allow read, write: if isAuditor();
    }

    // ============================================
    // NOTIFICATIONS COLLECTION
    // ============================================

    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if isAuthenticated() &&
                     request.auth.uid == resource.data.userId;

      // Users can update their own notifications (mark as read)
      allow update: if isAuthenticated() &&
                       request.auth.uid == resource.data.userId &&
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['isRead']);

      // Users can delete their own notifications
      allow delete: if isAuthenticated() &&
                       request.auth.uid == resource.data.userId;

      // System/Auditors can create notifications for any user
      allow create: if isAuditor();
    }

    // ============================================
    // CLIENTS COLLECTION (existing)
    // ============================================

    match /clients/{clientId} {
      // Auditors have full access
      allow read, write: if isAuditor();

      // Client users can read their own client data
      allow read: if isClientUser(clientId);

      // Subcollections (projects, reports, etc.)
      match /{document=**} {
        // Auditors have full access
        allow read, write: if isAuditor();

        // Client users can read their client's data
        allow read: if isClientUser(clientId);
      }
    }

    // ============================================
    // DEFAULT: DENY ALL
    // ============================================

    // Deny access to any other collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### How to Deploy Security Rules

**Option 1: Firebase Console (Manual)**
1. Go to Firebase Console → Your Project
2. Navigate to Firestore Database → Rules
3. Copy and paste the rules above
4. Click "Publish"

**Option 2: Firebase CLI (Automated)**
Save the rules to `firestore.rules` in your project root, then:

```bash
firebase deploy --only firestore:rules
```

---

## 🧪 Testing the Configuration

### Test 1: Create Task as Auditor
```dart
// Should succeed
final taskProvider = context.read<TaskProvider>();
await taskProvider.createTask(task);
```

### Test 2: Client Staff Tries to Create Task
```dart
// Should fail (permission denied)
final taskProvider = context.read<TaskProvider>();
await taskProvider.createTask(task);  // Error: Missing permissions
```

### Test 3: Client Staff Updates Their Task
```dart
// Should succeed
final taskProvider = context.read<TaskProvider>();
await taskProvider.submitTask(
  taskId: taskId,
  staffComments: 'Done!',
);
```

### Test 4: Client Staff Tries to Update Someone Else's Task
```dart
// Should fail (permission denied)
final taskProvider = context.read<TaskProvider>();
await taskProvider.submitTask(
  taskId: otherPersonsTaskId,  // Error: Not assigned to you
  staffComments: 'Done!',
);
```

---

## ⚠️ Important Notes

1. **Deploy indexes BEFORE deploying the app** - Otherwise queries will fail
2. **Test security rules in Firebase Console** - Use the Rules Playground
3. **Monitor Firestore usage** - Check for expensive queries
4. **Review rules periodically** - Ensure they match your security requirements
5. **Backup data before deploying** - Especially when updating rules

---

## 📈 Performance Considerations

### Index Efficiency
- Composite indexes allow efficient filtering and sorting
- Array-contains queries (for assignedTo) require specific indexes
- Order matters in composite indexes (most selective field first)

### Query Optimization
- Use `limit()` for pagination
- Avoid `whereIn` with large arrays
- Use `startAt`/`endAt` for date range queries
- Cache frequently accessed data locally

### Cost Management
- Monitor reads/writes in Firebase Console
- Use real-time listeners wisely (they count as reads)
- Consider batching writes
- Clean up old notifications periodically

---

## 🔄 Maintenance

### Regular Tasks
1. **Weekly**: Check index usage in Firebase Console
2. **Monthly**: Review security rule violations
3. **Quarterly**: Audit user permissions
4. **Annually**: Archive/delete old completed tasks

### Monitoring Queries
```dart
// Enable Firestore logging in development
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

## 📚 Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Query Performance](https://firebase.google.com/docs/firestore/query-data/queries#performance_considerations)

---

**Last Updated:** 2025-01-26
**Version:** 1.0 (Phase 1 - Data Foundation)
