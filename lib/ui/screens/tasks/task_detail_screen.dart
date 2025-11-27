import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _staffCommentsController = TextEditingController();
  final _adminCommentsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _staffCommentsController.dispose();
    _adminCommentsController.dispose();
    super.dispose();
  }

  Future<void> _startTask(BuildContext context, TaskProvider taskProvider) async {
    setState(() => _isLoading = true);

    final success = await taskProvider.startTask(widget.taskId);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task started' : 'Failed to start task'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _submitTask(BuildContext context, TaskProvider taskProvider) async {
    if (_staffCommentsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add comments before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await taskProvider.submitTask(
      taskId: widget.taskId,
      staffComments: _staffCommentsController.text.trim(),
      complianceStatus: true,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task submitted for review' : 'Failed to submit task'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _staffCommentsController.clear();
      }
    }
  }

  Future<void> _approveTask(BuildContext context, TaskProvider taskProvider) async {
    setState(() => _isLoading = true);

    final success = await taskProvider.approveTask(
      taskId: widget.taskId,
      adminComments: _adminCommentsController.text.trim().isNotEmpty
          ? _adminCommentsController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task approved' : 'Failed to approve task'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _adminCommentsController.clear();
      }
    }
  }

  Future<void> _rejectTask(BuildContext context, TaskProvider taskProvider) async {
    if (_adminCommentsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add comments before rejecting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await taskProvider.rejectTask(
      taskId: widget.taskId,
      adminComments: _adminCommentsController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task sent back for revision' : 'Failed to reject task'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );

      if (success) {
        _adminCommentsController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return FutureBuilder<TaskModel?>(
          future: taskProvider.getTaskById(widget.taskId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Task Details'),
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Task Details'),
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Task not found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final task = snapshot.data!;
            final isAssignedToMe = task.assignedTo.contains(currentUser?.email);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Task Details'),
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge
                          _buildStatusBadge(task),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: Platform.isIOS ? 22 : 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Description
                          if (task.description.isNotEmpty) ...[
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: Platform.isIOS ? 15 : 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Task Details
                          _buildInfoCard(task),
                          const SizedBox(height: 16),

                          // Staff Comments Section (if staff)
                          if (isAssignedToMe && task.status == TaskStatus.inProgress) ...[
                            _buildStaffCommentsSection(context, taskProvider),
                            const SizedBox(height: 16),
                          ],

                          // Submitted Comments (read-only)
                          if (task.staffComments.isNotEmpty) ...[
                            _buildSubmittedComments(task),
                            const SizedBox(height: 16),
                          ],

                          // Admin Review Section
                          if (task.status == TaskStatus.pendingReview) ...[
                            _buildAdminReviewSection(context, taskProvider),
                            const SizedBox(height: 16),
                          ],

                          // Admin Comments (read-only)
                          if (task.adminComments.isNotEmpty) ...[
                            _buildAdminComments(task),
                            const SizedBox(height: 16),
                          ],

                          // Action Buttons
                          if (isAssignedToMe) _buildActionButtons(context, task, taskProvider),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(TaskModel task) {
    Color statusColor;
    String statusText;

    switch (task.status) {
      case TaskStatus.assigned:
        statusColor = const Color(0xFF2196F3);
        statusText = 'Assigned';
        break;
      case TaskStatus.inProgress:
        statusColor = const Color(0xFFFF9800);
        statusText = 'In Progress';
        break;
      case TaskStatus.pendingReview:
        statusColor = const Color(0xFF9C27B0);
        statusText = 'Pending Review';
        break;
      case TaskStatus.completed:
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Completed';
        break;
      case TaskStatus.incomplete:
        statusColor = const Color(0xFFF44336);
        statusText = 'Incomplete';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: Platform.isIOS ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildPriorityBadge(task.priority),
        if (task.isOverdue) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Overdue',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: Platform.isIOS ? 13 : 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case TaskPriority.low:
        color = const Color(0xFF4CAF50);
        text = 'Low';
        break;
      case TaskPriority.medium:
        color = const Color(0xFFFF9800);
        text = 'Medium';
        break;
      case TaskPriority.high:
        color = const Color(0xFFF44336);
        text = 'High';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: Platform.isIOS ? 13 : 14,
        ),
      ),
    );
  }

  Widget _buildInfoCard(TaskModel task) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'Due Date',
              '${dateFormat.format(task.dueDate)} at ${timeFormat.format(task.dueDate)}'),
          const Divider(height: 24),
          _buildInfoRow(Icons.person_outline, 'Assigned To', task.assignedTo.join(', ')),
          const Divider(height: 24),
          _buildInfoRow(Icons.source_outlined, 'Source',
              task.source == TaskSource.audit ? 'Audit' : 'Standalone'),
          if (task.repeatFrequency != null) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.repeat, 'Frequency', task.repeatFrequency!),
          ],
          if (task.startedAt != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
                Icons.play_circle_outline, 'Started', dateFormat.format(task.startedAt!)),
          ],
          if (task.completedAt != null) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.check_circle_outline, 'Completed',
                dateFormat.format(task.completedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFE91E63)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 12 : 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 14 : 15,
                  color: const Color(0xFF222222),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCommentsSection(BuildContext context, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Work Notes',
            style: TextStyle(
              fontSize: Platform.isIOS ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _staffCommentsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the work completed...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedComments(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment_outlined, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Staff Notes',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.staffComments,
            style: TextStyle(
              fontSize: Platform.isIOS ? 14 : 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReviewSection(BuildContext context, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Review',
            style: TextStyle(
              fontSize: Platform.isIOS ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminCommentsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add review comments (optional for approval, required for rejection)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveTask(context, taskProvider),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectTask(context, taskProvider),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminComments(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 20, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Admin Comments',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.adminComments,
            style: TextStyle(
              fontSize: Platform.isIOS ? 14 : 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TaskModel task, TaskProvider taskProvider) {
    if (task.status == TaskStatus.assigned) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startTask(context, taskProvider),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (task.status == TaskStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _submitTask(context, taskProvider),
          icon: const Icon(Icons.send),
          label: const Text('Submit for Review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
