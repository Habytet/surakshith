import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/data/providers/user_provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:surakshith/data/providers/report_provider.dart';
import 'package:surakshith/data/providers/audit_area_provider.dart';
import 'package:surakshith/data/providers/responsible_person_provider.dart';
import 'package:surakshith/data/providers/audit_issue_provider.dart';
import 'package:surakshith/data/providers/audit_area_entry_provider.dart';
import 'package:surakshith/data/providers/fssai_report_provider.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:surakshith/data/providers/task_template_provider.dart';
import 'package:surakshith/data/providers/notification_provider.dart';
import 'package:surakshith/data/providers/task_generator_provider.dart';
import 'package:surakshith/data/services/background_sync_service.dart';
import 'package:surakshith/ui/screens/auth/login_screen.dart';
import 'package:surakshith/ui/widgets/auth/role_based_router.dart';
import 'package:surakshith/services/hive_service.dart';
import 'package:surakshith/services/fcm_service.dart';
import 'package:surakshith/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize FCM Service
  await FCMService().initialize();

  // Enable Firestore offline persistence (replaces Hive)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize Hive (will be removed gradually as we migrate)
  await HiveService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuditAreaProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ResponsiblePersonProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuditIssueProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuditAreaEntryProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => FssaiReportProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskTemplateProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskGeneratorProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => BackgroundSyncService(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Surakshith',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authProvider.isAuthenticated
                ? const RoleBasedRouter()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
