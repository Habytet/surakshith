import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:surakshith/ui/screens/tasks/task_detail_screen.dart';

/// Tasks screen for client users
/// Shows only tasks assigned to them
class ClientTasksScreen extends StatefulWidget {
  final UserModel user;

  const ClientTasksScreen({super.key, required this.user});

  @override
  State<ClientTasksScreen> createState() => _ClientTasksScreenState();
}

class _ClientTasksScreenState extends State<ClientTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFE91E63),
            labelColor: const Color(0xFFE91E63),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: TextStyle(
              fontSize: Platform.isIOS ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Assigned'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),

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
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Task stats
        _buildTaskStats(),

        // Tasks list
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TaskList(user: widget.user, statusFilter: null, searchQuery: _searchQuery),
              _TaskList(user: widget.user, statusFilter: TaskStatus.assigned, searchQuery: _searchQuery),
              _TaskList(user: widget.user, statusFilter: TaskStatus.inProgress, searchQuery: _searchQuery),
              _TaskList(user: widget.user, statusFilter: TaskStatus.completed, searchQuery: _searchQuery),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStats() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Get tasks assigned to this user
        final myTasks = taskProvider.getTasksByAssignee(widget.user.email);
        final assigned = myTasks.where((t) => t.status == TaskStatus.assigned).length;
        final inProgress = myTasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completed = myTasks.where((t) => t.status == TaskStatus.completed).length;
        final overdue = myTasks.where((t) =>
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
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: Platform.isIOS ? 9 : 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _TaskList extends StatelessWidget {
  final UserModel user;
  final TaskStatus? statusFilter;
  final String searchQuery;

  const _TaskList({
    required this.user,
    this.statusFilter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Get tasks assigned to this user
        var tasks = taskProvider.getTasksByAssignee(user.email);

        // Apply status filter
        if (statusFilter != null) {
          tasks = tasks.where((t) => t.status == statusFilter).toList();
        }

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          tasks = tasks.where((task) {
            return task.title.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query);
          }).toList();
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
