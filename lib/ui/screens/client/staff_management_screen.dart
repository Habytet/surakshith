import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/providers/user_provider.dart';
import 'package:surakshith/data/providers/task_provider.dart';

/// Staff management screen for Hotel Admins
/// Shows all staff members for their hotel and their task stats
class StaffManagementScreen extends StatefulWidget {
  final UserModel user;

  const StaffManagementScreen({super.key, required this.user});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header stats
        _buildStaffStats(),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search staff...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Staff list
        Expanded(
          child: _StaffList(
            clientId: widget.user.clientId ?? '',
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffStats() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final clientId = widget.user.clientId ?? '';
        final staffList = userProvider.getClientStaffByClient(clientId);
        final activeStaff = staffList.where((s) => s.isActive).length;
        final inactiveStaff = staffList.where((s) => !s.isActive).length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Staff', staffList.length, Icons.people),
              _buildStatDivider(),
              _buildStatItem('Active', activeStaff, Icons.check_circle),
              _buildStatDivider(),
              _buildStatItem('Inactive', inactiveStaff, Icons.block, isWarning: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, {bool isWarning = false}) {
    return Column(
      children: [
        Icon(
          icon,
          color: isWarning ? Colors.amber : Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: Platform.isIOS ? 10 : 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _StaffList extends StatelessWidget {
  final String clientId;
  final String searchQuery;

  const _StaffList({
    required this.clientId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, TaskProvider>(
      builder: (context, userProvider, taskProvider, child) {
        // Get all staff for this client (both active and inactive for management)
        var staffList = userProvider.getUsersByClient(clientId)
            .where((u) => u.role == UserRole.clientStaff)
            .toList();

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          staffList = staffList.where((staff) {
            return staff.displayName.toLowerCase().contains(query) ||
                staff.email.toLowerCase().contains(query);
          }).toList();
        }

        if (staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No staff members found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Staff will appear here once added by the auditor',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: staffList.length,
          itemBuilder: (context, index) {
            final staff = staffList[index];
            // Get task stats for this staff member
            final tasks = taskProvider.getTasksByAssignee(staff.email);
            return _StaffCard(
              staff: staff,
              tasks: tasks,
              onToggleActive: () => _toggleStaffStatus(context, staff, userProvider),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleStaffStatus(
    BuildContext context,
    UserModel staff,
    UserProvider userProvider,
  ) async {
    final action = staff.isActive ? 'deactivate' : 'activate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${action.substring(0, 1).toUpperCase()}${action.substring(1)} Staff',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to $action ${staff.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: staff.isActive ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
            ),
            child: Text(
              action.substring(0, 1).toUpperCase() + action.substring(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      bool success;
      if (staff.isActive) {
        success = await userProvider.deactivateUser(staff.uid);
      } else {
        success = await userProvider.activateUser(staff.uid);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Staff ${action}d successfully'
                  : userProvider.errorMessage,
            ),
            backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}

class _StaffCard extends StatelessWidget {
  final UserModel staff;
  final List<TaskModel> tasks;
  final VoidCallback onToggleActive;

  const _StaffCard({
    required this.staff,
    required this.tasks,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((t) =>
      t.status != TaskStatus.completed
    ).length;
    final completedTasks = tasks.where((t) =>
      t.status == TaskStatus.completed
    ).length;
    final overdueTasks = tasks.where((t) =>
      t.dueDate.isBefore(DateTime.now()) &&
      t.status != TaskStatus.completed
    ).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: !staff.isActive ? Colors.grey.withValues(alpha: 0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: staff.isActive
                          ? [const Color(0xFF2196F3), const Color(0xFF00BCD4)]
                          : [Colors.grey, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      staff.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Platform.isIOS ? 18 : 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              staff.displayName,
                              style: TextStyle(
                                fontSize: Platform.isIOS ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: staff.isActive ? const Color(0xFF222222) : Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!staff.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Inactive',
                                style: TextStyle(
                                  fontSize: Platform.isIOS ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.email,
                        style: TextStyle(
                          fontSize: Platform.isIOS ? 12 : 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Toggle active button
                IconButton(
                  icon: Icon(
                    staff.isActive ? Icons.block : Icons.check_circle_outline,
                    color: staff.isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: onToggleActive,
                  tooltip: staff.isActive ? 'Deactivate' : 'Activate',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task stats row
            Row(
              children: [
                _buildTaskStat(
                  'Pending',
                  pendingTasks,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildTaskStat(
                  'Completed',
                  completedTasks,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildTaskStat(
                  'Overdue',
                  overdueTasks,
                  Colors.red,
                ),
                const Spacer(),
                Text(
                  'Total: ${tasks.length}',
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStat(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: Platform.isIOS ? 11 : 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
