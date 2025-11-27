import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/ui/screens/client/client_reports_screen.dart';
import 'package:surakshith/ui/screens/client/client_tasks_screen.dart';
import 'package:surakshith/ui/screens/client/staff_management_screen.dart';

/// Home screen for client users (clientAdmin and clientStaff)
/// Shows reports and tasks specific to their client
class ClientHomeScreen extends StatefulWidget {
  final UserModel user;

  const ClientHomeScreen({super.key, required this.user});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  late final List<String> _titles;

  bool get _isAdmin => widget.user.isClientAdmin;

  @override
  void initState() {
    super.initState();

    // Admin sees Reports, Tasks, and Staff Management
    // Staff only sees Tasks (no reports access)
    if (_isAdmin) {
      _screens = [
        ClientReportsScreen(user: widget.user),
        ClientTasksScreen(user: widget.user),
        StaffManagementScreen(user: widget.user),
      ];
      _titles = ['My Reports', 'My Tasks', 'Staff'];
    } else {
      // Hotel Staff - only tasks, no reports
      _screens = [
        ClientTasksScreen(user: widget.user),
      ];
      _titles = ['My Tasks'];
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: Platform.isIOS ? 18 : 20,
              ),
            ),
            Text(
              widget.user.displayName,
              style: TextStyle(
                fontSize: Platform.isIOS ? 11 : 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: Platform.isIOS ? 8 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Admin sees Reports, Tasks, Staff
                // Staff only sees Tasks
                if (_isAdmin) ...[
                  _buildNavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Reports',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.task_outlined,
                    activeIcon: Icons.task,
                    label: 'Tasks',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Staff',
                    index: 2,
                  ),
                ] else ...[
                  // Staff only - just tasks (single item, centered)
                  _buildNavItem(
                    icon: Icons.task_outlined,
                    activeIcon: Icons.task,
                    label: 'Tasks',
                    index: 0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE91E63).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFFE91E63) : Colors.grey[600],
                size: Platform.isIOS ? 24 : 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFE91E63) : Colors.grey[600],
                  fontSize: Platform.isIOS ? 11 : 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
