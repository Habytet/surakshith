import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:surakshith/data/providers/user_provider.dart';
import 'package:surakshith/ui/screens/tasks/standalone_task_form_screen.dart';
import 'package:surakshith/ui/screens/tasks/task_detail_screen.dart';

/// Main task list screen with filtering and search
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize task provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final firebaseUser = authProvider.currentUser;

      if (firebaseUser != null) {
        final userModel = userProvider.getUserByEmail(firebaseUser.email ?? '');
        // Set filters based on user role
        if (userModel != null && userModel.role == UserRole.auditor) {
          // Auditors see all tasks
          taskProvider.init();
        } else {
          // Client users see only their tasks
          taskProvider.init();
          if (firebaseUser.email != null) {
            taskProvider.setAssigneeFilter(firebaseUser.email!);
          }
        }
      } else {
        // Initialize anyway to load tasks
        taskProvider.init();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseUser = authProvider.currentUser;
    final userModel = firebaseUser != null
        ? userProvider.getUserByEmail(firebaseUser.email ?? '')
        : null;
    final isAuditor = userModel?.role == UserRole.auditor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                Provider.of<TaskProvider>(context, listen: false)
                    .setSearchQuery(value);
              },
            ),
          ),

          // Task stats
          _buildTaskStats(),

          // Task list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(statusFilter: null),
                _TaskList(statusFilter: TaskStatus.assigned),
                _TaskList(statusFilter: TaskStatus.inProgress),
                _TaskList(statusFilter: TaskStatus.completed),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAuditor
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StandaloneTaskFormScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
            )
          : null,
    );
  }

  Widget _buildTaskStats() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final assigned = tasks.where((t) => t.status == TaskStatus.assigned).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final overdue = tasks.where((t) =>
          t.dueDate.isBefore(DateTime.now()) &&
          t.status != TaskStatus.completed
        ).length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Assigned', assigned, Icons.task_alt),
              _buildStatDivider(),
              _buildStatItem('In Progress', inProgress, Icons.pending_actions),
              _buildStatDivider(),
              _buildStatItem('Completed', completed, Icons.check_circle),
              _buildStatDivider(),
              _buildStatItem('Overdue', overdue, Icons.warning, isWarning: true),
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

// ============================================
// TASK LIST VIEW
// ============================================

class _TaskList extends StatelessWidget {
  final TaskStatus? statusFilter;

  const _TaskList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taskProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  taskProvider.errorMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Apply status filter
        List<TaskModel> tasks = taskProvider.tasks;
        if (statusFilter != null) {
          tasks = tasks.where((t) => t.status == statusFilter).toList();
        }

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _TaskCard(task: tasks[index]);
          },
        );
      },
    );
  }
}

// ============================================
// TASK CARD
// ============================================

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(task.status),
                            const SizedBox(width: 8),
                            if (task.type == TaskType.repetitive)
                              _buildRepetitiveChip(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Source icon
                  Icon(
                    task.source == TaskSource.audit
                        ? Icons.assignment
                        : Icons.task,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                task.description,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 13 : 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  // Due date
                  Icon(
                    isOverdue ? Icons.warning : Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(task.dueDate),
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 11 : 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),

                  // Assigned users count
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.assignedTo.length}',
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.assigned:
        color = Colors.blue;
        label = 'Assigned';
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        label = 'In Progress';
        break;
      case TaskStatus.pendingReview:
        color = Colors.purple;
        label = 'Pending Review';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case TaskStatus.incomplete:
        color = Colors.red;
        label = 'Incomplete';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Platform.isIOS ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRepetitiveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.repeat,
            size: 12,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(width: 4),
          Text(
            'Repetitive',
            style: TextStyle(
              fontSize: Platform.isIOS ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE91E63),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final days = difference.inDays.abs();
      if (days == 0) {
        return 'Overdue today';
      } else if (days == 1) {
        return 'Overdue by 1 day';
      } else {
        return 'Overdue by $days days';
      }
    } else {
      final days = difference.inDays;
      if (days == 0) {
        return 'Due today';
      } else if (days == 1) {
        return 'Due tomorrow';
      } else if (days < 7) {
        return 'Due in $days days';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }
}

// ============================================
// FILTER BOTTOM SHEET
// ============================================

class _FilterBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      taskProvider.clearFilters();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Source filter
              const Text(
                'Task Source',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: taskProvider.selectedSource == null,
                    onTap: () => taskProvider.setSourceFilter(null),
                  ),
                  _buildFilterChip(
                    label: 'Audit',
                    isSelected: taskProvider.selectedSource == TaskSource.audit,
                    onTap: () => taskProvider.setSourceFilter(TaskSource.audit),
                  ),
                  _buildFilterChip(
                    label: 'Standalone',
                    isSelected:
                        taskProvider.selectedSource == TaskSource.standalone,
                    onTap: () =>
                        taskProvider.setSourceFilter(TaskSource.standalone),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Priority filter
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: taskProvider.selectedPriority == null,
                    onTap: () => taskProvider.setPriorityFilter(null),
                  ),
                  _buildFilterChip(
                    label: 'High',
                    isSelected:
                        taskProvider.selectedPriority == TaskPriority.high,
                    onTap: () =>
                        taskProvider.setPriorityFilter(TaskPriority.high),
                    color: Colors.red,
                  ),
                  _buildFilterChip(
                    label: 'Medium',
                    isSelected:
                        taskProvider.selectedPriority == TaskPriority.medium,
                    onTap: () =>
                        taskProvider.setPriorityFilter(TaskPriority.medium),
                    color: Colors.orange,
                  ),
                  _buildFilterChip(
                    label: 'Low',
                    isSelected:
                        taskProvider.selectedPriority == TaskPriority.low,
                    onTap: () =>
                        taskProvider.setPriorityFilter(TaskPriority.low),
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFFE91E63);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          border: Border.all(color: chipColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.w600,
            fontSize: Platform.isIOS ? 12 : 13,
          ),
        ),
      ),
    );
  }
}
