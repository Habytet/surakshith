import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/models/task_template_model.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/models/client_model.dart';
import 'package:surakshith/data/models/project_model.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:surakshith/data/providers/task_template_provider.dart';
import 'package:surakshith/data/providers/user_provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for creating standalone tasks (one-time or repetitive)
class StandaloneTaskFormScreen extends StatefulWidget {
  const StandaloneTaskFormScreen({super.key});

  @override
  State<StandaloneTaskFormScreen> createState() =>
      _StandaloneTaskFormScreenState();
}

class _StandaloneTaskFormScreenState extends State<StandaloneTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Task type
  TaskType _taskType = TaskType.oneTime;

  // Client and project
  ClientModel? _selectedClient;
  ProjectModel? _selectedProject;

  // Assignment
  List<UserModel> _selectedUsers = [];
  DateTime? _dueDate;

  // Priority
  TaskPriority _priority = TaskPriority.medium;

  // Repetitive task fields
  RepeatFrequency _repeatFrequency = RepeatFrequency.daily;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectClient() async {
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final clients = clientProvider.getAllClients();

    if (clients.isEmpty) {
      _showSnackBar('No clients available', isError: true);
      return;
    }

    final selected = await showDialog<ClientModel>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Client',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                title: Text(
                  client.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(client.contactNumber),
                onTap: () => Navigator.of(context).pop(client),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedClient = selected;
        _selectedProject = null; // Reset project
        _selectedUsers = []; // Reset users
      });
    }
  }

  Future<void> _selectProject() async {
    if (_selectedClient == null) {
      _showSnackBar('Please select a client first', isError: true);
      return;
    }

    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final projects = projectProvider.getProjectsByClient(_selectedClient!.id);

    if (projects.isEmpty) {
      _showSnackBar('No projects available for this client', isError: true);
      return;
    }

    final selected = await showDialog<ProjectModel>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Project',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                title: Text(
                  project.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(project.contactName ?? 'No contact'),
                onTap: () => Navigator.of(context).pop(project),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedProject = selected;
      });
    }
  }

  Future<void> _selectUsers() async {
    if (_selectedClient == null) {
      _showSnackBar('Please select a client first', isError: true);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final clientUsers = userProvider.getUsersByClient(_selectedClient!.id);

    if (clientUsers.isEmpty) {
      _showSnackBar('No users found for this client', isError: true);
      return;
    }

    final selected = await showDialog<List<UserModel>>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        clientUsers: clientUsers,
        initialSelected: _selectedUsers,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedUsers = selected;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFE91E63),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _dueDate ?? DateTime.now().add(const Duration(hours: 24)),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: const Color(0xFFE91E63),
                    onPrimary: Colors.white,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFE91E63),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      _showSnackBar('Please select a client', isError: true);
      return;
    }

    if (_selectedProject == null) {
      _showSnackBar('Please select a project', isError: true);
      return;
    }

    if (_selectedUsers.isEmpty) {
      _showSnackBar('Please assign at least one user', isError: true);
      return;
    }

    if (_taskType == TaskType.oneTime && _dueDate == null) {
      _showSnackBar('Please set a due date', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      if (_taskType == TaskType.oneTime) {
        // Create one-time task
        await _createOneTimeTask(currentUser.email!);
      } else {
        // Create repetitive task template
        await _createRepetitiveTaskTemplate(currentUser.email!);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _createOneTimeTask(String createdBy) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    int tasksCreated = 0;

    // Create individual task for each assignee
    for (final user in _selectedUsers) {
      final taskId = await taskProvider.createStandaloneTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        clientId: _selectedClient!.id,
        projectId: _selectedProject!.id,
        assignedTo: [user.email],
        createdBy: createdBy,
        assignedDate: DateTime.now(),
        dueDate: _dueDate!,
        type: TaskType.oneTime,
        priority: _priority,
      );

      if (taskId != null) {
        tasksCreated++;
      }
    }

    if (tasksCreated > 0 && mounted) {
      _showSnackBar('Created $tasksCreated task(s) successfully');
      Navigator.of(context).pop();
    } else {
      _showSnackBar('Failed to create tasks', isError: true);
    }
  }

  Future<void> _createRepetitiveTaskTemplate(String createdBy) async {
    final templateProvider =
        Provider.of<TaskTemplateProvider>(context, listen: false);

    final template = TaskTemplateModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      clientId: _selectedClient!.id,
      projectId: _selectedProject!.id,
      defaultAssignees: _selectedUsers.map((u) => u.email).toList(),
      priority: _priority,
      frequency: _repeatFrequency,
      reminderTime: _reminderTime,
      isActive: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final templateId = await templateProvider.createTemplate(template);

    if (templateId != null && mounted) {
      _showSnackBar('Created repetitive task template successfully');
      Navigator.of(context).pop();
    } else {
      _showSnackBar('Failed to create template', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task type selector
                    _buildTaskTypeSelector(),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'e.g., Check fridge temperature',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Provide detailed instructions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Client selection
                    _buildSelectionTile(
                      icon: Icons.business,
                      title: 'Client',
                      value: _selectedClient?.name ?? 'Select client',
                      onTap: _selectClient,
                    ),
                    const SizedBox(height: 12),

                    // Project selection
                    _buildSelectionTile(
                      icon: Icons.apartment,
                      title: 'Project',
                      value: _selectedProject?.name ?? 'Select project',
                      onTap: _selectProject,
                      enabled: _selectedClient != null,
                    ),
                    const SizedBox(height: 24),

                    // Priority selector
                    _buildPrioritySelector(),
                    const SizedBox(height: 24),

                    // User assignment
                    _buildSelectionTile(
                      icon: Icons.people,
                      title: 'Assign To',
                      value: _selectedUsers.isEmpty
                          ? 'Select users'
                          : '${_selectedUsers.length} user(s) selected',
                      onTap: _selectUsers,
                      enabled: _selectedClient != null,
                    ),
                    if (_selectedUsers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSelectedUsersChips(),
                    ],
                    const SizedBox(height: 24),

                    // Due date (for one-time tasks)
                    if (_taskType == TaskType.oneTime) ...[
                      _buildSelectionTile(
                        icon: Icons.calendar_today,
                        title: 'Due Date',
                        value: _dueDate != null
                            ? _formatDateTime(_dueDate!)
                            : 'Set due date',
                        onTap: _selectDueDate,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Repeat settings (for repetitive tasks)
                    if (_taskType == TaskType.repetitive) ...[
                      _buildRepeatFrequencySelector(),
                      const SizedBox(height: 16),
                      _buildSelectionTile(
                        icon: Icons.access_time,
                        title: 'Reminder Time',
                        value: _formatTime(_reminderTime),
                        onTap: _selectReminderTime,
                      ),
                      const SizedBox(height: 16),
                      _buildRepetitiveTaskInfo(),
                      const SizedBox(height: 24),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _taskType == TaskType.oneTime
                              ? 'Create Task'
                              : 'Create Template',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTaskTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTaskTypeButton(
              label: 'One-Time Task',
              isSelected: _taskType == TaskType.oneTime,
              onTap: () => setState(() => _taskType = TaskType.oneTime),
            ),
          ),
          Expanded(
            child: _buildTaskTypeButton(
              label: 'Repetitive Task',
              isSelected: _taskType == TaskType.repetitive,
              onTap: () => setState(() => _taskType = TaskType.repetitive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: Platform.isIOS ? 13 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPriorityChip(TaskPriority.low, 'Low', Colors.green),
            const SizedBox(width: 8),
            _buildPriorityChip(TaskPriority.medium, 'Medium', Colors.orange),
            const SizedBox(width: 8),
            _buildPriorityChip(TaskPriority.high, 'High', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(
    TaskPriority priority,
    String label,
    Color color,
  ) {
    final isSelected = _priority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: Platform.isIOS ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Frequency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFrequencyChip(RepeatFrequency.daily, 'Daily'),
            const SizedBox(width: 8),
            _buildFrequencyChip(RepeatFrequency.weekly, 'Weekly'),
            const SizedBox(width: 8),
            _buildFrequencyChip(RepeatFrequency.monthly, 'Monthly'),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyChip(RepeatFrequency frequency, String label) {
    final isSelected = _repeatFrequency == frequency;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repeatFrequency = frequency),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE91E63) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFE91E63) : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: Platform.isIOS ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? const Color(0xFFE91E63) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: enabled ? const Color(0xFFE91E63) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUsersChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedUsers.map((user) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: const Color(0xFFE91E63),
            child: Text(
              user.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          label: Text(user.displayName),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedUsers.removeWhere((u) => u.uid == user.uid);
            });
          },
          backgroundColor: Colors.grey[100],
        );
      }).toList(),
    );
  }

  Widget _buildRepetitiveTaskInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This will create a template that automatically generates tasks ${_repeatFrequency.name} at ${_formatTime(_reminderTime)} for the assigned users.',
              style: TextStyle(
                fontSize: Platform.isIOS ? 11 : 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// USER SELECTION DIALOG
// ============================================

class _UserSelectionDialog extends StatefulWidget {
  final List<UserModel> clientUsers;
  final List<UserModel> initialSelected;

  const _UserSelectionDialog({
    required this.clientUsers,
    required this.initialSelected,
  });

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  late List<UserModel> _selectedUsers;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _searchQuery.isEmpty
        ? widget.clientUsers
        : widget.clientUsers.where((user) {
            final query = _searchQuery.toLowerCase();
            return user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query);
          }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Users',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),

            // Selected count
            if (_selectedUsers.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFFE91E63)),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedUsers.length} user(s) selected',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // User list
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSelected =
                      _selectedUsers.any((u) => u.uid == user.uid);

                  return CheckboxListTile(
                    title: Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user.email),
                    value: isSelected,
                    activeColor: const Color(0xFFE91E63),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          if (!_selectedUsers.any((u) => u.uid == user.uid)) {
                            _selectedUsers.add(user);
                          }
                        } else {
                          _selectedUsers.removeWhere((u) => u.uid == user.uid);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedUsers),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
