import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/providers/user_provider.dart';

/// Reusable widget for assigning tasks to users
/// Can be embedded in audit forms or standalone task creation
class TaskAssignmentWidget extends StatefulWidget {
  final String clientId;
  final List<UserModel> initialSelectedUsers;
  final DateTime? initialDueDate;
  final ValueChanged<List<UserModel>> onUsersChanged;
  final ValueChanged<DateTime?> onDueDateChanged;

  const TaskAssignmentWidget({
    super.key,
    required this.clientId,
    this.initialSelectedUsers = const [],
    this.initialDueDate,
    required this.onUsersChanged,
    required this.onDueDateChanged,
  });

  @override
  State<TaskAssignmentWidget> createState() => _TaskAssignmentWidgetState();
}

class _TaskAssignmentWidgetState extends State<TaskAssignmentWidget> {
  List<UserModel> _selectedUsers = [];
  DateTime? _selectedDueDate;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.initialSelectedUsers);
    _selectedDueDate = widget.initialDueDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUserSelectionDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Get users for this client (both admins and staff)
    final clientUsers = userProvider.getUsersByClient(widget.clientId);

    if (clientUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No users found for this client'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Temporary selection for dialog
    List<UserModel> tempSelectedUsers = List.from(_selectedUsers);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter users based on search
          final filteredUsers = _searchQuery.isEmpty
              ? clientUsers
              : clientUsers.where((user) {
                  final query = _searchQuery.toLowerCase();
                  return user.displayName.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query);
                }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Select Staff to Assign',
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
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFE91E63),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selected count
                  if (tempSelectedUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFE91E63),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tempSelectedUsers.length} user(s) selected',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                              fontSize: Platform.isIOS ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // User list
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No users available'
                                  : 'No matching users found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Platform.isIOS ? 13 : 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected = tempSelectedUsers
                                  .any((u) => u.uid == user.uid);

                              return CheckboxListTile(
                                title: Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: Platform.isIOS ? 11 : 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.isClientAdmin
                                            ? Colors.blue.withValues(alpha: 0.1)
                                            : Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        user.isClientAdmin
                                            ? 'Admin'
                                            : 'Staff',
                                        style: TextStyle(
                                          fontSize: Platform.isIOS ? 10 : 11,
                                          fontWeight: FontWeight.w600,
                                          color: user.isClientAdmin
                                              ? Colors.blue[700]
                                              : Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                value: isSelected,
                                activeColor: const Color(0xFFE91E63),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      if (!tempSelectedUsers
                                          .any((u) => u.uid == user.uid)) {
                                        tempSelectedUsers.add(user);
                                      }
                                    } else {
                                      tempSelectedUsers
                                          .removeWhere((u) => u.uid == user.uid);
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
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  setState(() {
                    _selectedUsers = tempSelectedUsers;
                  });
                  widget.onUsersChanged(_selectedUsers);
                  Navigator.of(context).pop();
                },
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
        },
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
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

    if (picked != null) {
      // Also pick time
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDueDate ?? DateTime.now().add(const Duration(hours: 24)),
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

      if (timePicked != null) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );

        setState(() {
          _selectedDueDate = selectedDateTime;
        });
        widget.onDueDateChanged(_selectedDueDate);
      }
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
    widget.onDueDateChanged(null);
  }

  void _removeUser(UserModel user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.uid == user.uid);
    });
    widget.onUsersChanged(_selectedUsers);
  }

  String _formatDateTime(DateTime date) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.task_alt,
              color: Color(0xFFE91E63),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Assign as Task (Optional)',
              style: TextStyle(
                fontSize: Platform.isIOS ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Assign to button
        InkWell(
          onTap: _showUserSelectionDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedUsers.isEmpty ? Icons.person_add : Icons.people,
                  color: const Color(0xFFE91E63),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedUsers.isEmpty
                        ? 'Select staff to assign'
                        : '${_selectedUsers.length} user(s) selected',
                    style: TextStyle(
                      color: _selectedUsers.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                      fontSize: Platform.isIOS ? 14 : 15,
                      fontWeight: _selectedUsers.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFE91E63),
                ),
              ],
            ),
          ),
        ),

        // Selected users chips
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
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
                label: Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeUser(user),
                backgroundColor: Colors.grey[100],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],

        // Due date picker (only show if users selected)
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFFE91E63),
              ),
              title: const Text(
                'Task Deadline',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _selectedDueDate != null
                    ? _formatDateTime(_selectedDueDate!)
                    : 'Tap to set deadline',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 12 : 13,
                  color: _selectedDueDate != null
                      ? Colors.grey[800]
                      : Colors.grey[500],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedDueDate != null)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                      onPressed: _clearDueDate,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                ],
              ),
              onTap: () => _selectDueDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],

        // Info message
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
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
                    'A task will be created and assigned to the selected users when you save this audit entry.',
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 11 : 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
