import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/audit_issue_provider.dart';

class AuditIssueManagementScreen extends StatelessWidget {
  const AuditIssueManagementScreen({super.key});

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _AddAuditIssueDialog(),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, String id, String currentName, List<int> currentClauseNumbers) async {
    await showDialog(
      context: context,
      builder: (context) => _EditAuditIssueDialog(
        id: id,
        currentName: currentName,
        currentClauseNumbers: currentClauseNumbers,
      ),
    );
  }

  Future<void> _deleteItem(
      BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Audit Issue',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<AuditIssueProvider>(context, listen: false);
      final success = await provider.deleteAuditIssue(id: id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Audit issue deleted successfully'
                  : provider.errorMessage,
            ),
            backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'Audit Issues',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Consumer<AuditIssueProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF44336),
              ),
            );
          }

          final items = provider.getAllAuditIssues();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No audit issues found',
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a new issue',
                    style: TextStyle(fontSize: Platform.isIOS ? 13 : 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final createdAt = item.createdAt;

              // Format clause numbers for display
              final clauseText = item.clauseNumbers.isEmpty
                  ? 'No clauses'
                  : 'Clauses: ${item.clauseNumbers.join(', ')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF44336), Color(0xFFEF5350)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Platform.isIOS ? 14 : 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (createdAt != null)
                        Text(
                          'Created: ${createdAt.toString().split('.')[0]}',
                          style: TextStyle(fontSize: Platform.isIOS ? 11 : 12, color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        clauseText,
                        style: TextStyle(
                          fontSize: Platform.isIOS ? 11 : 12,
                          color: const Color(0xFFE91E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3)),
                        onPressed: () => _showEditDialog(
                          context,
                          item.id,
                          item.name,
                          item.clauseNumbers,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                        onPressed: () => _deleteItem(context, item.id, item.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFFF44336),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// Add Audit Issue Dialog (Stateful)
class _AddAuditIssueDialog extends StatefulWidget {
  const _AddAuditIssueDialog();

  @override
  State<_AddAuditIssueDialog> createState() => _AddAuditIssueDialogState();
}

class _AddAuditIssueDialogState extends State<_AddAuditIssueDialog> {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final List<int> selectedClauseNumbers = [];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Add Audit Issue',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Issue Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter issue name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _ClauseNumberMultiSelect(
                selectedNumbers: selectedClauseNumbers,
                onChanged: (numbers) {
                  setState(() {
                    selectedClauseNumbers.clear();
                    selectedClauseNumbers.addAll(numbers);
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
        ),
        Consumer<AuditIssueProvider>(
          builder: (context, provider, _) {
            return ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        final success = await provider.addAuditIssue(
                          name: nameController.text.trim(),
                          clauseNumbers: selectedClauseNumbers,
                        );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Audit issue added successfully'
                                    : provider.errorMessage,
                              ),
                              backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Add'),
            );
          },
        ),
      ],
    );
  }
}

// Edit Audit Issue Dialog (Stateful)
class _EditAuditIssueDialog extends StatefulWidget {
  final String id;
  final String currentName;
  final List<int> currentClauseNumbers;

  const _EditAuditIssueDialog({
    required this.id,
    required this.currentName,
    required this.currentClauseNumbers,
  });

  @override
  State<_EditAuditIssueDialog> createState() => _EditAuditIssueDialogState();
}

class _EditAuditIssueDialogState extends State<_EditAuditIssueDialog> {
  late TextEditingController nameController;
  final formKey = GlobalKey<FormState>();
  late List<int> selectedClauseNumbers;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    selectedClauseNumbers = List.from(widget.currentClauseNumbers);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Edit Audit Issue',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Issue Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter issue name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _ClauseNumberMultiSelect(
                selectedNumbers: selectedClauseNumbers,
                onChanged: (numbers) {
                  setState(() {
                    selectedClauseNumbers.clear();
                    selectedClauseNumbers.addAll(numbers);
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final provider =
                  Provider.of<AuditIssueProvider>(context, listen: false);

              final success = await provider.updateAuditIssue(
                id: widget.id,
                name: nameController.text.trim(),
                clauseNumbers: selectedClauseNumbers,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Audit issue updated successfully'
                          : provider.errorMessage,
                    ),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF44336),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Clause Number Multi-Select Widget
class _ClauseNumberMultiSelect extends StatefulWidget {
  final List<int> selectedNumbers;
  final ValueChanged<List<int>> onChanged;

  const _ClauseNumberMultiSelect({
    required this.selectedNumbers,
    required this.onChanged,
  });

  @override
  State<_ClauseNumberMultiSelect> createState() => _ClauseNumberMultiSelectState();
}

class _ClauseNumberMultiSelectState extends State<_ClauseNumberMultiSelect> {
  final searchController = TextEditingController();
  String searchQuery = '';

  // All clause numbers 1-51
  static final List<int> allClauseNumbers = List.generate(51, (index) => index + 1);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<int> get filteredNumbers {
    if (searchQuery.isEmpty) return allClauseNumbers;
    return allClauseNumbers
        .where((num) => num.toString().contains(searchQuery))
        .toList();
  }

  void _toggleNumber(int number) {
    final newSelection = List<int>.from(widget.selectedNumbers);
    if (newSelection.contains(number)) {
      newSelection.remove(number);
    } else {
      newSelection.add(number);
    }
    newSelection.sort();
    widget.onChanged(newSelection);
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Select Clause Numbers',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search numbers...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredNumbers.length,
                      itemBuilder: (context, index) {
                        final number = filteredNumbers[index];
                        final isSelected = widget.selectedNumbers.contains(number);

                        return CheckboxListTile(
                          title: Text('Clause $number'),
                          value: isSelected,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (checked) {
                            setDialogState(() {
                              _toggleNumber(number);
                            });
                            setState(() {}); // Update parent widget
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
                  searchController.clear();
                  searchQuery = '';
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showSelectionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedNumbers.isEmpty
                      ? 'Select Clause Numbers (1-51)'
                      : '${widget.selectedNumbers.length} clause(s) selected',
                  style: TextStyle(
                    color: widget.selectedNumbers.isEmpty ? Colors.grey[600] : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
              ],
            ),
          ),
        ),
        if (widget.selectedNumbers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedNumbers.map((number) {
              return Chip(
                label: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFE91E63),
                deleteIconColor: Colors.white,
                onDeleted: () {
                  _toggleNumber(number);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
