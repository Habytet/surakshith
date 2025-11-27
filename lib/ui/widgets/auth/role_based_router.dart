import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/providers/user_provider.dart';
import 'package:surakshith/data/providers/task_generator_provider.dart';
import 'package:surakshith/services/fcm_service.dart';
import 'package:surakshith/ui/screens/home/home_screen.dart';
import 'package:surakshith/ui/screens/client/client_home_screen.dart';

/// Routes authenticated users to appropriate home screen based on their role
class RoleBasedRouter extends StatefulWidget {
  const RoleBasedRouter({super.key});

  @override
  State<RoleBasedRouter> createState() => _RoleBasedRouterState();
}

class _RoleBasedRouterState extends State<RoleBasedRouter> {
  @override
  void initState() {
    super.initState();
    // Trigger auto-generation of tasks and save FCM token after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskGenerator = context.read<TaskGeneratorProvider>();
      taskGenerator.autoGenerateIfNeeded();

      // Save FCM token to Firestore
      _saveFCMToken();
    });
  }

  Future<void> _saveFCMToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FCMService().saveTokenToFirestore(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUser = FirebaseAuth.instance.currentUser;

    if (currentAuthUser == null) {
      // Should not happen as auth check happens before routing here
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Find the user model by email
        final userModel = userProvider.getUserByEmail(currentAuthUser.email!);

        if (userModel == null) {
          // User not found in Firestore - show loading or error
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading user data...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        // Route based on user role
        switch (userModel.role) {
          case UserRole.auditor:
            // Auditors get full app access
            return const HomeScreen();

          case UserRole.clientAdmin:
          case UserRole.clientStaff:
            // Client users get limited portal access
            return ClientHomeScreen(user: userModel);
        }
      },
    );
  }
}
