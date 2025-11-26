import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surakshith/ui/screens/settings/user_management_screen.dart';
import 'package:surakshith/ui/screens/settings/client_management_screen.dart';
import 'package:surakshith/ui/screens/settings/audit_area_management_screen.dart';
import 'package:surakshith/ui/screens/settings/responsible_person_management_screen.dart';
import 'package:surakshith/ui/screens/settings/audit_issue_management_screen.dart';
import 'package:surakshith/ui/screens/settings/sync_status_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF6E40)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE91E63).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: TextStyle(
                                fontSize: Platform.isIOS ? 20 : 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF222222),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: TextStyle(
                                fontSize: Platform.isIOS ? 13 : 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                'Management',
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
                    color: Colors.black.withOpacity(0.04),
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
                    iconColor: const Color(0xFFE91E63),
                    iconBgColor: const Color(0xFFE91E63).withOpacity(0.1),
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
                    iconBgColor: const Color(0xFF3F51B5).withOpacity(0.1),
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                'Audit Configuration',
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
                    color: Colors.black.withOpacity(0.04),
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
                    iconBgColor: const Color(0xFF9C27B0).withOpacity(0.1),
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
                    iconBgColor: const Color(0xFFFF9800).withOpacity(0.1),
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
                    iconBgColor: const Color(0xFFF44336).withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.04),
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
                    iconBgColor: const Color(0xFF2196F3).withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.04),
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
                    iconBgColor: const Color(0xFF607D8B).withOpacity(0.1),
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Logout from your account',
                    iconColor: const Color(0xFFE53935),
                    iconBgColor: const Color(0xFFE53935).withOpacity(0.1),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
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
    required VoidCallback onTap,
    required bool showDivider,
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
                Icon(
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
