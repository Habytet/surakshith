import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/audit_area_entry_model.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/providers/audit_area_entry_provider.dart';
import 'package:surakshith/data/providers/audit_area_provider.dart';
import 'package:surakshith/data/providers/responsible_person_provider.dart';
import 'package:surakshith/data/providers/audit_issue_provider.dart';
import 'package:surakshith/data/providers/task_provider.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/ui/widgets/tasks/task_assignment_widget.dart';

class AuditAreaFormScreen extends StatefulWidget {
  final String clientId;
  final String projectId;
  final String reportId;
  final AuditAreaEntryModel? entry; // null = add mode, non-null = edit mode

  const AuditAreaFormScreen({
    super.key,
    required this.clientId,
    required this.projectId,
    required this.reportId,
    this.entry,
  });

  @override
  State<AuditAreaFormScreen> createState() => _AuditAreaFormScreenState();
}

class _AuditAreaFormScreenState extends State<AuditAreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _observationController;
  late TextEditingController _recommendationController;
  final ImagePicker _picker = ImagePicker();

  final List<File> _newImages = [];
  late List<String> _existingImageUrls;
  late String? _selectedAuditAreaId;
  late String? _selectedResponsiblePersonId;
  late List<String> _selectedAuditIssueIds;
  late String _selectedRisk;
  late DateTime? _selectedDeadline;
  bool _isSaving = false;

  // Task assignment fields
  List<UserModel> _selectedTaskAssignees = [];
  DateTime? _taskDueDate;

  bool get _isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();

    // Initialize based on mode
    if (_isEditMode) {
      // Edit mode - pre-populate with existing data
      _observationController = TextEditingController(text: widget.entry!.observation);
      _recommendationController = TextEditingController(text: widget.entry!.recommendation);
      _existingImageUrls = List<String>.from(widget.entry!.imageUrls);
      _selectedAuditAreaId = widget.entry!.auditAreaId;
      _selectedResponsiblePersonId = widget.entry!.responsiblePersonId.isEmpty ? null : widget.entry!.responsiblePersonId;
      _selectedAuditIssueIds = List<String>.from(widget.entry!.auditIssueIds);
      _selectedRisk = widget.entry!.risk;
      _selectedDeadline = widget.entry!.deadlineDate;
    } else {
      // Add mode - initialize with defaults
      _observationController = TextEditingController();
      _recommendationController = TextEditingController();
      _existingImageUrls = [];
      _selectedAuditAreaId = null;
      _selectedResponsiblePersonId = null;
      _selectedAuditIssueIds = [];
      _selectedRisk = 'low';
      _selectedDeadline = null;
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 2 images allowed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 960,
        maxHeight: 540,
      );

      if (photo != null) {
        setState(() {
          _newImages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image from camera: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 2 images allowed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 960,
        maxHeight: 540,
      );

      if (image != null) {
        setState(() {
          _newImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image from gallery: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
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
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _clearDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveEntry() async {
    // Prevent double-tap
    if (_isSaving) return;

    // Validate audit area selection manually
    if (_selectedAuditAreaId == null || _selectedAuditAreaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an audit area'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final entryProvider =
          Provider.of<AuditAreaEntryProvider>(context, listen: false);

      // Combine all images for validation
      final allImageFiles = _newImages.isNotEmpty ? _newImages : null;

      if (_isEditMode) {
        // Edit mode - update existing entry
        final success = await entryProvider.updateEntry(
          clientId: widget.clientId,
          projectId: widget.projectId,
          reportId: widget.reportId,
          id: widget.entry!.id,
          auditAreaId: _selectedAuditAreaId,
          responsiblePersonId: _selectedResponsiblePersonId,
          auditIssueIds: _selectedAuditIssueIds,
          risk: _selectedRisk,
          observation: _observationController.text.trim(),
          recommendation: _recommendationController.text.trim(),
          deadlineDate: _selectedDeadline,
          newImageFiles: allImageFiles,
          existingImageUrls: _existingImageUrls,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (success) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Audit entry updated successfully!'),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(entryProvider.errorMessage),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Add mode - create new entry
        final entryId = await entryProvider.addEntry(
          clientId: widget.clientId,
          projectId: widget.projectId,
          reportId: widget.reportId,
          auditAreaId: _selectedAuditAreaId!,
          responsiblePersonId: _selectedResponsiblePersonId ?? '',
          auditIssueIds: _selectedAuditIssueIds,
          risk: _selectedRisk,
          observation: _observationController.text.trim(),
          recommendation: _recommendationController.text.trim(),
          deadlineDate: _selectedDeadline,
          imageFiles: allImageFiles,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (entryId != null) {
            // Audit entry created successfully
            // Now create task if users are assigned
            if (_selectedTaskAssignees.isNotEmpty) {
              await _createTaskFromAuditEntry(entryId);
            }

            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _selectedTaskAssignees.isEmpty
                      ? 'Audit entry added successfully!'
                      : 'Audit entry added and task(s) created!',
                ),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(entryProvider.errorMessage),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _createTaskFromAuditEntry(String entryId) async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final auditAreaProvider = Provider.of<AuditAreaProvider>(context, listen: false);
      final auditIssueProvider = Provider.of<AuditIssueProvider>(context, listen: false);

      // Get current user (auditor)
      final currentUser = authProvider.currentUser;
      if (currentUser == null) return;

      // Get audit area name for task title
      final allAuditAreas = auditAreaProvider.getAllAuditAreas();
      final auditAreaIdx = allAuditAreas.indexWhere((area) => area.id == _selectedAuditAreaId);
      if (auditAreaIdx == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit area not found')),
        );
        return;
      }
      final auditArea = allAuditAreas[auditAreaIdx];

      // Get audit issue names
      final allAuditIssues = auditIssueProvider.getAllAuditIssues();
      final issueNames = _selectedAuditIssueIds.map((issueId) {
        final issueIdx = allAuditIssues.indexWhere((i) => i.id == issueId);
        return issueIdx != -1 ? allAuditIssues[issueIdx].name : issueId;
      }).toList();

      // Generate task title
      final taskTitle = issueNames.isEmpty
          ? 'Fix issue in ${auditArea.name}'
          : 'Fix: ${issueNames.join(', ')} in ${auditArea.name}';

      // Generate task description
      final taskDescription = '''
Audit Issue Found:
- Area: ${auditArea.name}
- Risk Level: ${_selectedRisk.toUpperCase()}

${_observationController.text.trim().isNotEmpty ? 'Observation:\n${_observationController.text.trim()}\n\n' : ''}${_recommendationController.text.trim().isNotEmpty ? 'Recommendation:\n${_recommendationController.text.trim()}' : ''}
'''.trim();

      // Create task for each assignee
      for (final assignee in _selectedTaskAssignees) {
        await taskProvider.createTaskFromAudit(
          auditReportId: widget.reportId,
          auditEntryId: entryId,
          auditAreaId: _selectedAuditAreaId!,
          auditIssueIds: _selectedAuditIssueIds,
          title: taskTitle,
          description: taskDescription,
          assignedTo: [assignee.email],
          clientId: widget.clientId,
          projectId: widget.projectId,
          createdBy: currentUser.email!,
          dueDate: _taskDueDate ?? DateTime.now().add(const Duration(days: 7)),
          risk: _selectedRisk,
          images: _existingImageUrls, // Attach audit images to task
        );
      }
    } catch (e) {
      // Task creation failed, but audit entry was saved
      // Show warning but don't fail completely
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Task creation failed - $e'),
            backgroundColor: Colors.orange,
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
        title: Text(
          _isEditMode ? 'Edit Audit Area' : 'New Audit Area',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add Attachment Section
              Text(
                'Attachments (Max 2)',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt, color: Color(0xFFE91E63)),
                      label: Text(
                        'Camera',
                        style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE91E63)),
                        foregroundColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library, color: Color(0xFFE91E63)),
                      label: Text(
                        'Gallery',
                        style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE91E63)),
                        foregroundColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Existing Images (only in edit mode)
              if (_existingImageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Existing Images:',
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_existingImageUrls[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              // New Images
              if (_newImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _isEditMode ? 'New Images:' : 'Selected Images:',
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_newImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Audit Area Dropdown (Searchable)
              _AuditAreaSelect(
                selectedAreaId: _selectedAuditAreaId,
                onChanged: (selectedId) {
                  setState(() {
                    _selectedAuditAreaId = selectedId;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Responsible Person Dropdown
              Consumer<ResponsiblePersonProvider>(
                builder: (context, responsibleProvider, _) {
                  final responsiblePersons =
                      responsibleProvider.getAllResponsiblePersons();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedResponsiblePersonId,
                    decoration: InputDecoration(
                      labelText: 'Responsible Person (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFE91E63)),
                    ),
                    items: responsiblePersons.map((person) {
                      return DropdownMenuItem<String>(
                        value: person.id,
                        child: Text(person.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedResponsiblePersonId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Audit Issue Multi-Select
              _AuditIssueMultiSelect(
                selectedIssueIds: _selectedAuditIssueIds,
                onChanged: (selectedIds) {
                  setState(() {
                    _selectedAuditIssueIds = selectedIds;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Risk Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRisk,
                decoration: InputDecoration(
                  labelText: 'Risk',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.warning, color: Color(0xFFE91E63)),
                ),
                items: const [
                  DropdownMenuItem<String>(value: 'low', child: Text('Low')),
                  DropdownMenuItem<String>(
                      value: 'medium', child: Text('Medium')),
                  DropdownMenuItem<String>(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRisk = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Observation TextField
              TextFormField(
                controller: _observationController,
                decoration: InputDecoration(
                  labelText: 'Observation (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.visibility, color: Color(0xFFE91E63)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Recommendation TextField
              TextFormField(
                controller: _recommendationController,
                decoration: InputDecoration(
                  labelText: 'Recommendation (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.recommend, color: Color(0xFFE91E63)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Deadline Date Picker
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today,
                      color: Color(0xFFE91E63)),
                  title: Text(
                    'Deadline Date (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Platform.isIOS ? 14 : 15,
                    ),
                  ),
                  subtitle: Text(
                    _selectedDeadline != null ? _formatDate(_selectedDeadline!) : 'Select Date',
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 12 : 13,
                      color: _selectedDeadline != null ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                          onPressed: _clearDeadline,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                    ],
                  ),
                  onTap: () => _selectDeadline(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Task Assignment Widget (only show in add mode, not edit mode)
              if (!_isEditMode) ...[
                TaskAssignmentWidget(
                  clientId: widget.clientId,
                  initialSelectedUsers: _selectedTaskAssignees,
                  initialDueDate: _taskDueDate,
                  onUsersChanged: (users) {
                    setState(() {
                      _selectedTaskAssignees = users;
                    });
                  },
                  onDueDateChanged: (dueDate) {
                    setState(() {
                      _taskDueDate = dueDate;
                    });
                  },
                ),
                const SizedBox(height: 32),
              ],

              // Save/Update Button
              Consumer<AuditAreaEntryProvider>(
                builder: (context, entryProvider, _) {
                  final isLoading = entryProvider.isLoading || _isSaving;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Update' : 'Save',
                            style: TextStyle(
                              fontSize: Platform.isIOS ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Audit Area Select Widget (Searchable Single-Select)
class _AuditAreaSelect extends StatefulWidget {
  final String? selectedAreaId;
  final ValueChanged<String?> onChanged;

  const _AuditAreaSelect({
    required this.selectedAreaId,
    required this.onChanged,
  });

  @override
  State<_AuditAreaSelect> createState() => _AuditAreaSelectState();
}

class _AuditAreaSelectState extends State<_AuditAreaSelect> {
  final searchController = TextEditingController();
  String searchQuery = '';
  String? _validationError;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showSelectionDialog() {
    // Get the audit areas BEFORE showing dialog
    final auditAreaProvider = Provider.of<AuditAreaProvider>(context, listen: false);
    final allAreas = auditAreaProvider.getAllAuditAreas();

    // Create local copy of selected ID for dialog state
    String? localSelectedId = widget.selectedAreaId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter areas based on search query
          final filteredAreas = searchQuery.isEmpty
              ? allAreas
              : allAreas
                  .where((area) =>
                      area.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Select Audit Area',
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
                      hintText: 'Search audit areas...',
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
                    child: filteredAreas.isEmpty
                        ? Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No audit areas available'
                                  : 'No matching audit areas found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Platform.isIOS ? 13 : 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredAreas.length,
                            itemBuilder: (context, index) {
                              final area = filteredAreas[index];
                              final isSelected = localSelectedId == area.id;

                              return RadioListTile<String>(
                                title: Text(area.name),
                                value: area.id,
                                groupValue: localSelectedId,
                                activeColor: const Color(0xFFE91E63),
                                onChanged: (value) {
                                  setDialogState(() {
                                    localSelectedId = value;
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
                  searchController.clear();
                  searchQuery = '';
                  Navigator.of(context).pop();
                },
                child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () {
                  searchController.clear();
                  searchQuery = '';
                  // Update parent widget only when Done is clicked
                  widget.onChanged(localSelectedId);
                  setState(() {
                    _validationError = null;
                  });
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

  // Custom validation method to be called by form
  String? validate() {
    if (widget.selectedAreaId == null || widget.selectedAreaId!.isEmpty) {
      setState(() {
        _validationError = 'Please select audit area';
      });
      return _validationError;
    }
    setState(() {
      _validationError = null;
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Get audit areas for displaying names
    final auditAreaProvider = Provider.of<AuditAreaProvider>(context, listen: false);
    final allAreas = auditAreaProvider.getAllAuditAreas();

    // Build a map for quick lookup
    final areaMap = {for (var area in allAreas) area.id: area.name};

    final selectedAreaName = widget.selectedAreaId != null
        ? areaMap[widget.selectedAreaId!] ?? 'Unknown Area'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showSelectionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _validationError != null ? const Color(0xFFE53935) : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_special, color: Color(0xFFE91E63)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedAreaName ?? 'Select Audit Area',
                    style: TextStyle(
                      color: selectedAreaName != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
              ],
            ),
          ),
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _validationError!,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Audit Issue Multi-Select Widget
class _AuditIssueMultiSelect extends StatefulWidget {
  final List<String> selectedIssueIds;
  final ValueChanged<List<String>> onChanged;

  const _AuditIssueMultiSelect({
    required this.selectedIssueIds,
    required this.onChanged,
  });

  @override
  State<_AuditIssueMultiSelect> createState() => _AuditIssueMultiSelectState();
}

class _AuditIssueMultiSelectState extends State<_AuditIssueMultiSelect> {
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showSelectionDialog() {
    // Get the audit issues BEFORE showing dialog
    final auditIssueProvider = Provider.of<AuditIssueProvider>(context, listen: false);
    final allIssues = auditIssueProvider.getAllAuditIssues();

    // Create local copy of selected IDs for dialog state
    List<String> localSelectedIds = List<String>.from(widget.selectedIssueIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter issues based on search query
          final filteredIssues = searchQuery.isEmpty
              ? allIssues
              : allIssues
                  .where((issue) =>
                      issue.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Select Audit Issues',
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
                      hintText: 'Search audit issues...',
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
                    child: filteredIssues.isEmpty
                        ? Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No audit issues available'
                                  : 'No matching audit issues found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Platform.isIOS ? 13 : 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredIssues.length,
                            itemBuilder: (context, index) {
                              final issue = filteredIssues[index];
                              final isSelected = localSelectedIds.contains(issue.id);

                              return CheckboxListTile(
                                title: Text(issue.name),
                                subtitle: issue.clauseNumbers.isNotEmpty
                                    ? Text(
                                        'Clauses: ${issue.clauseNumbers.join(', ')}',
                                        style: TextStyle(
                                          fontSize: Platform.isIOS ? 11 : 12,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                    : null,
                                value: isSelected,
                                activeColor: const Color(0xFFE91E63),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (localSelectedIds.contains(issue.id)) {
                                      localSelectedIds.remove(issue.id);
                                    } else {
                                      localSelectedIds.add(issue.id);
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
                  searchController.clear();
                  searchQuery = '';
                  // Update parent widget only when Done is clicked
                  widget.onChanged(localSelectedIds);
                  setState(() {});
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
    // Get audit issues for displaying names
    final auditIssueProvider = Provider.of<AuditIssueProvider>(context, listen: false);
    final allIssues = auditIssueProvider.getAllAuditIssues();

    // Build a map for quick lookup
    final issueMap = {for (var issue in allIssues) issue.id: issue.name};

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
                  widget.selectedIssueIds.isEmpty
                      ? 'Select Audit Issues (Optional)'
                      : '${widget.selectedIssueIds.length} issue(s) selected',
                  style: TextStyle(
                    color: widget.selectedIssueIds.isEmpty ? Colors.grey[600] : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
              ],
            ),
          ),
        ),
        if (widget.selectedIssueIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedIssueIds.map((issueId) {
              final issueName = issueMap[issueId] ?? issueId;

              return Chip(
                label: Text(
                  issueName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFE91E63),
                deleteIconColor: Colors.white,
                onDeleted: () {
                  // Remove this issue from selection
                  final newSelection = List<String>.from(widget.selectedIssueIds)..remove(issueId);
                  widget.onChanged(newSelection);
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
