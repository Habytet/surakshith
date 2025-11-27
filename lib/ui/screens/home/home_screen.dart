import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/auth_provider.dart' as app_auth;
import 'package:surakshith/data/providers/notification_provider.dart';
import 'package:surakshith/ui/screens/reports/reports_screen.dart';
import 'package:surakshith/ui/screens/tasks/task_list_screen.dart';
import 'package:surakshith/ui/screens/settings/settings_screen.dart';
import 'package:surakshith/ui/screens/notifications/notification_center_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/floating_nav_bar.dart';
import '../../../widgets/common/gradient_header.dart';
import '../../../widgets/common/staggered_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<FloatingNavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      FloatingNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        gradientColors: [AppColors.primary, AppColors.primaryLight],
      ),
      FloatingNavItem(
        icon: Icons.assessment_outlined,
        activeIcon: Icons.assessment_rounded,
        label: 'Reports',
        gradientColors: [AppColors.primary, AppColors.primaryLight],
      ),
      FloatingNavItem(
        icon: Icons.task_outlined,
        activeIcon: Icons.task_rounded,
        label: 'Tasks',
        gradientColors: [AppColors.primary, AppColors.primaryLight],
      ),
      FloatingNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
        gradientColors: [AppColors.primary, AppColors.primaryLight],
      ),
    ];

    // Sync all data from Firebase in background after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAllDataFromFirebase();
    });
  }

  // Sync clients and projects from Firebase
  Future<void> _syncAllDataFromFirebase() async {
    // Clients now use real-time Firestore listeners - no manual sync needed!
  }

  void _logout() async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationCenterScreen(),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String _getUserName() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser.displayName!.split(' ').first;
    }
    return currentUser?.email?.split('@').first ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTabContent(
            userName: _getUserName(),
            greeting: _getGreeting(),
            onNotificationTap: _navigateToNotifications,
            onLogout: _logout,
          ),
          const ReportsScreen(),
          const TaskListScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
        child: FloatingNavBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  final String userName;
  final String greeting;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogout;

  const _HomeTabContent({
    required this.userName,
    required this.greeting,
    required this.onNotificationTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        // Gradient Header with notification badge
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return StreamBuilder<int>(
              stream: notificationProvider
                  .getUnreadCountStream(currentUser?.email ?? ''),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return GradientHeader(
                  userName: userName,
                  greeting: greeting,
                  date: DateTime.now(),
                  onNotificationTap: onNotificationTap,
                  notificationCount: unreadCount,
                );
              },
            );
          },
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions Section
                StaggeredListItem(
                  index: 0,
                  child: Text(
                    'Quick Actions',
                    style: AppTextStyles.h3,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Feature Cards
                StaggeredListItem(
                  index: 1,
                  child: _FeatureCard(
                    icon: Icons.assessment_rounded,
                    title: 'Create Report',
                    description: 'Generate comprehensive audit reports',
                    gradientColors: [
                      const Color(0xFF2196F3),
                      const Color(0xFF00BCD4)
                    ],
                    onTap: () {
                      // Navigate to reports tab
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                StaggeredListItem(
                  index: 2,
                  child: _FeatureCard(
                    icon: Icons.business_rounded,
                    title: 'Manage Clients',
                    description: 'Configure clients and projects',
                    gradientColors: [
                      const Color(0xFF9C27B0),
                      const Color(0xFFE91E63)
                    ],
                    onTap: () {
                      // Navigate to clients
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                StaggeredListItem(
                  index: 3,
                  child: _FeatureCard(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Cloud Sync',
                    description: 'All your data backed up automatically',
                    gradientColors: [
                      const Color(0xFF4CAF50),
                      const Color(0xFF8BC34A)
                    ],
                    onTap: () {},
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceXL),

                // Logout button
                StaggeredListItem(
                  index: 4,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.textSecondary),
                      label: Text(
                        'Sign Out',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom padding for navigation bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: AppDimensions.iconL,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    description,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ],
        ),
      ),
    );
  }
}
