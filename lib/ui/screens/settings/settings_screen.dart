import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/task_generator_provider.dart';
import 'package:surakshith/ui/screens/settings/user_management_screen.dart';
import 'package:surakshith/ui/screens/settings/client_management_screen.dart';
import 'package:surakshith/ui/screens/settings/audit_area_management_screen.dart';
import 'package:surakshith/ui/screens/settings/responsible_person_management_screen.dart';
import 'package:surakshith/ui/screens/settings/audit_issue_management_screen.dart';
import 'package:surakshith/ui/screens/settings/sync_status_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingXL,
                  AppDimensions.paddingL,
                  AppDimensions.paddingXL,
                  AppDimensions.paddingL,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: AppDimensions.spaceXXS),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: AppTextStyles.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Management Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingXL,
                AppDimensions.paddingL,
                AppDimensions.paddingXL,
                AppDimensions.paddingS,
              ),
              child: Text(
                'Management',
                style: AppTextStyles.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.people_outline,
                    title: 'User Management',
                    subtitle: 'Manage team members and permissions',
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.business_outlined,
                    title: 'Client Management',
                    subtitle: 'Manage clients and their projects',
                    iconColor: const Color(0xFF3F51B5),
                    iconBgColor: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientManagementScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Audit Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingXL,
                AppDimensions.paddingL,
                AppDimensions.paddingXL,
                AppDimensions.paddingS,
              ),
              child: Text(
                'Audit Configuration',
                style: AppTextStyles.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Audit Areas',
                    subtitle: 'Configure audit area templates',
                    iconColor: const Color(0xFF9C27B0),
                    iconBgColor: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuditAreaManagementScreen(),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.person_outline_outlined,
                    title: 'Responsible Persons',
                    subtitle: 'Manage audit responsibility assignments',
                    iconColor: const Color(0xFFFF9800),
                    iconBgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResponsiblePersonManagementScreen(),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.warning_amber_outlined,
                    title: 'Audit Issues',
                    subtitle: 'Define issue categories and priorities',
                    iconColor: const Color(0xFFF44336),
                    iconBgColor: const Color(0xFFF44336).withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuditIssueManagementScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Tasks Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Consumer<TaskGeneratorProvider>(
                    builder: (context, taskGen, child) {
                      return _buildSettingsTile(
                        context,
                        icon: Icons.autorenew,
                        title: 'Generate Repetitive Tasks',
                        subtitle: taskGen.templatesNeedingGeneration > 0
                            ? '${taskGen.templatesNeedingGeneration} template(s) ready'
                            : taskGen.lastGenerationResult ?? 'Generate tasks from templates',
                        iconColor: const Color(0xFF4CAF50),
                        iconBgColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        trailing: taskGen.isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        onTap: taskGen.isGenerating
                            ? null
                            : () async {
                                final success = await taskGen.generateDailyTasks();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        taskGen.lastGenerationResult ?? 'Done',
                                      ),
                                      backgroundColor:
                                          success ? Colors.green : Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                        showDivider: false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Data Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                'Data',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.cloud_queue_outlined,
                    title: 'Backup Status',
                    subtitle: 'View cloud backup progress',
                    iconColor: const Color(0xFF2196F3),
                    iconBgColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SyncStatusScreen(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Support Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    iconColor: const Color(0xFF607D8B),
                    iconBgColor: const Color(0xFF607D8B).withValues(alpha: 0.1),
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Logout from your account',
                    iconColor: const Color(0xFFE53935),
                    iconBgColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing for floating nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback? onTap,
    required bool showDivider,
    Widget? trailing,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: Platform.isIOS ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: Platform.isIOS ? 12 : 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[200],
            ),
          ),
      ],
    );
  }
}
