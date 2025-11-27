# 📋 Quick Reference Card - Firebase Cloud Functions

## 🚀 Deployment Commands (Copy-Paste These)

### First Time Setup:
```bash
# 1. Install Firebase CLI (one time only)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Go to project folder
cd /Users/haarisbasheer/AndroidStudioProjects/surakshith

# 4. Initialize functions (answer Yes to all questions)
firebase init functions

# 5. Install dependencies
cd functions
npm install

# 6. Deploy!
cd ..
firebase deploy --only functions
```

---

## 🔄 Update Functions Later:

```bash
# When you edit functions/index.js and want to deploy changes:
cd /Users/haarisbasheer/AndroidStudioProjects/surakshith
firebase deploy --only functions
```

---

## 📊 Useful Commands:

```bash
# View function logs (see what's happening)
firebase functions:log

# View logs for specific function
firebase functions:log --only onTaskCreated

# List all your Firebase projects
firebase projects:list

# Check which project you're using
firebase use

# Switch to different project
firebase use <project-id>

# Delete a specific function
firebase functions:delete <functionName>

# Deploy only one function (faster)
firebase deploy --only functions:onTaskCreated
```

---

## 📱 What Each Function Does:

| Function Name | When It Runs | Who Gets Notified |
|---------------|--------------|-------------------|
| `onTaskCreated` | When task is created in Firestore | Task assignees |
| `onTaskUpdated` | When task status changes | Depends on status (assignees or admin) |
| `onReportCreated` | When report is created | All users of that client |
| `checkOverdueTasks` | Every day at 9:00 AM | Assignees with overdue tasks |
| `cleanupOldNotifications` | Every Sunday at midnight | (maintenance, no notifications) |

---

## 🧪 Testing Checklist:

- [ ] Create a task → Assignee gets notification?
- [ ] Complete a task → Admin gets notification?
- [ ] Approve a task → Staff gets notification?
- [ ] Reject a task → Staff gets notification?
- [ ] Create a report → Client users get notification?

---

## ❌ Troubleshooting Quick Fixes:

### No notifications received?
```bash
# Check function logs
firebase functions:log

# Check if functions are deployed
firebase functions:list

# Redeploy
firebase deploy --only functions
```

### "Permission denied" error?
```bash
# Mac/Linux: Use sudo
sudo npm install -g firebase-tools

# Windows: Run Command Prompt as Administrator
```

### "Not authenticated" error?
```bash
# Login again
firebase login --reauth
```

### Want to see Firebase Console?
```bash
# Opens Firebase Console in browser
firebase open
```

---

## 🎯 Success Indicators:

After deployment, you should see:
```
✔  functions[onTaskCreated]: Successful create operation.
✔  functions[onTaskUpdated]: Successful create operation.
✔  functions[onReportCreated]: Successful create operation.
✔  functions[checkOverdueTasks]: Successful create operation.
✔  functions[cleanupOldNotifications]: Successful create operation.

✔  Deploy complete!
```

---

## 📍 Important File Locations:

- Cloud Functions code: `functions/index.js`
- Dependencies config: `functions/package.json`
- Full guide: `EASY_DEPLOYMENT_GUIDE.md`
- Firebase config: `firebase.json`

---

## 💡 Pro Tips:

1. **Always check logs** when testing: `firebase functions:log`
2. **Deploy is fast** (2-3 minutes), don't worry about redeploying
3. **Free tier is generous** - you won't be charged for normal usage
4. **Functions run on Google servers** - your computer can be off
5. **Changes require redeployment** - edit code, then deploy again

---

## 🆘 Emergency Commands:

```bash
# Something broken? Delete all functions and redeploy
firebase functions:delete --all
firebase deploy --only functions

# Reset everything
rm -rf functions/node_modules
cd functions
npm install
cd ..
firebase deploy --only functions

# View real-time logs (keeps watching)
firebase functions:log --tail
```

---

## ✅ Daily Workflow:

**Normal operation:** Nothing to do! Functions run automatically 24/7

**To make changes:**
1. Edit `functions/index.js`
2. Run: `firebase deploy --only functions`
3. Wait 2-3 minutes
4. Test!

---

## 📞 Support Links:

- Firebase Console: https://console.firebase.google.com
- Firebase Functions Docs: https://firebase.google.com/docs/functions
- Cloud Functions Pricing: https://firebase.google.com/pricing
- Your project: `firebase open`

---

**Remember:** After initial deployment, everything is automatic! You don't need to do anything unless you want to change the notification logic.

**🎉 Enjoy your automatic push notifications!**
