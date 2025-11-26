import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/report_model.dart';
import 'package:surakshith/data/providers/audit_area_entry_provider.dart';
import 'package:surakshith/data/providers/audit_area_provider.dart';
import 'package:surakshith/data/providers/audit_issue_provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:surakshith/data/providers/report_provider.dart';
import 'package:surakshith/data/services/background_sync_service.dart';
import 'package:surakshith/ui/screens/reports/audit_area_form_screen.dart';
import 'package:surakshith/ui/screens/reports/generate_report_screen.dart';

class ReportFormScreen extends StatefulWidget {
  final ReportModel? report; // null = create mode, non-null = edit mode

  const ReportFormScreen({super.key, this.report});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedClientId;
  late String? _selectedProjectId;
  late DateTime _selectedDate;
  late String _selectedStatus;
  final _contactNameController = TextEditingController();
  String? _currentReportId;
  String _reportNumber = '#001';
  bool _isPrimaryInfoExpanded = true;
  final BackgroundSyncService _syncService = BackgroundSyncService();
  bool _isSaving = false;
  bool _isAddingAuditArea = false;

  bool get _isEditMode => widget.report != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // Edit mode - initialize with existing report data
      _selectedClientId = widget.report!.clientId;
      _selectedProjectId = widget.report!.projectId;
      _selectedDate = widget.report!.reportDate;
      _selectedStatus = widget.report!.status;
      _contactNameController.text = widget.report!.contactName ?? '';
      _currentReportId = widget.report!.id;

      // Set current report in entry provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final entryProvider = Provider.of<AuditAreaEntryProvider>(context, listen: false);
        entryProvider.setCurrentReport(_currentReportId!);
      });
    } else {
      // Create mode - initialize with defaults
      _selectedClientId = null;
      _selectedProjectId = null;
      _selectedDate = DateTime.now();
      _selectedStatus = 'draft';
      _generateReportNumber();
    }
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _generateReportNumber() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final allReports = reportProvider.getAllReports();
    final reportCount = allReports.length + 1;
    setState(() {
      _reportNumber = '#${reportCount.toString().padLeft(3, '0')}';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveReport() async {
    // Prevent double-tap
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Check if all entries are synced
    final isSynced = await _syncService.isFullySynced();
    if (!isSynced && mounted) {
      final shouldWait = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sync in Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: Platform.isIOS ? 16 : 18,
            ),
          ),
          content: Text(
            'Some audit entries are still uploading. Do you want to wait for sync to complete?',
            style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Save Anyway', style: TextStyle(color: Colors.grey[700])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              child: const Text('Wait', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (shouldWait == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for sync to complete...',
                  style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
                ),
              ],
            ),
          ),
        );

        while (!(await _syncService.isFullySynced())) {
          await Future.delayed(const Duration(seconds: 1));
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (_isEditMode) {
      // Edit mode - update existing report
      final success = await reportProvider.updateReport(
        clientId: _selectedClientId!,
        projectId: _selectedProjectId!,
        id: _currentReportId!,
        reportDate: _selectedDate,
        status: _selectedStatus,
        contactName: _contactNameController.text.trim().isEmpty
            ? null
            : _contactNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report updated successfully!'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.errorMessage),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } else {
      // Create mode - create new report
      final reportId = await reportProvider.addReport(
        clientId: _selectedClientId!,
        projectId: _selectedProjectId!,
        reportDate: _selectedDate,
        status: 'draft',
        contactName: _contactNameController.text.trim().isEmpty
            ? null
            : _contactNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (reportId != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report saved successfully!'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.errorMessage),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  Future<void> _addAuditArea() async {
    // Prevent double-tap
    if (_isAddingAuditArea) return;

    setState(() {
      _isAddingAuditArea = true;
    });

    // Create report first if not created
    if (_currentReportId == null) {
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isAddingAuditArea = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in primary information first'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      final reportId = await reportProvider.addReport(
        clientId: _selectedClientId!,
        projectId: _selectedProjectId!,
        reportDate: _selectedDate,
        status: 'draft',
        contactName: _contactNameController.text.trim().isEmpty
            ? null
            : _contactNameController.text.trim(),
      );

      if (reportId == null) {
        if (mounted) {
          setState(() {
            _isAddingAuditArea = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.errorMessage),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }

      setState(() {
        _currentReportId = reportId;
      });

      final entryProvider =
          Provider.of<AuditAreaEntryProvider>(context, listen: false);
      entryProvider.setCurrentReport(reportId);
    }

    // Navigate to Add Audit Area screen
    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AuditAreaFormScreen(
            clientId: _selectedClientId!,
            projectId: _selectedProjectId!,
            reportId: _currentReportId!,
          ),
        ),
      );

      // Reset flag after navigation completes
      setState(() {
        _isAddingAuditArea = false;
      });

      if (result == true) {
        setState(() {});
      }
    }
  }

  Future<void> _editAuditEntry(entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuditAreaFormScreen(
          clientId: _selectedClientId!,
          projectId: _selectedProjectId!,
          reportId: entry.reportId,
          entry: entry,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  bool _hasUnsavedData() {
    // In edit mode, we assume there might be changes
    if (_isEditMode) {
      return true;
    }

    // Check if any form fields have data
    if (_selectedClientId != null ||
        _selectedProjectId != null ||
        _contactNameController.text.trim().isNotEmpty) {
      return true;
    }

    // Check if report has been created with audit entries
    if (_currentReportId != null) {
      final entryProvider = Provider.of<AuditAreaEntryProvider>(context, listen: false);
      final entries = entryProvider.getEntriesForCurrentReport();
      if (entries.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _onWillPop() async {
    // If currently saving, don't allow back
    if (_isSaving || _isAddingAuditArea) {
      return false;
    }

    // If no unsaved data, allow back
    if (!_hasUnsavedData()) {
      return true;
    }

    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard Changes?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 16 : 18,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to go back?',
          style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _deleteAuditEntry(String entryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Entry',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 16 : 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this audit entry?',
          style: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
        ),
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

    if (confirm == true && mounted) {
      final entryProvider =
          Provider.of<AuditAreaEntryProvider>(context, listen: false);
      final success = await entryProvider.deleteEntry(
        clientId: _selectedClientId!,
        projectId: _selectedProjectId!,
        reportId: _currentReportId!,
        id: entryId,
      );

      if (mounted) {
        if (success) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Audit entry deleted'),
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
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: Text(
          _isEditMode ? 'Edit Report' : 'New Report $_reportNumber',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Check if report has been created/saved
              if (_currentReportId == null || _selectedClientId == null || _selectedProjectId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please save the report first'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
                return;
              }

              // Navigate to Generate Report screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GenerateReportScreen(
                    clientId: _selectedClientId!,
                    projectId: _selectedProjectId!,
                    reportId: _currentReportId!,
                  ),
                ),
              );
            },
            child: Text(
              'Generate',
              style: TextStyle(
                color: const Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
                fontSize: Platform.isIOS ? 15 : 16,
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<ClientProvider, ProjectProvider>(
        builder: (context, clientProvider, projectProvider, child) {
          final clients = clientProvider.getAllClients();
          final projects = _selectedClientId != null
              ? projectProvider.getProjectsForCurrentClient()
              : [];

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary Information - Collapsible
                        Container(
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
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(),
                            collapsedShape: const RoundedRectangleBorder(),
                            title: Text(
                              'Primary Information',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: Platform.isIOS ? 15 : 16,
                              ),
                            ),
                            initiallyExpanded: _isPrimaryInfoExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _isPrimaryInfoExpanded = expanded;
                              });
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Client Dropdown (disabled in edit mode)
                                    if (_isEditMode) ...[
                                      // Read-only client display
                                      InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Client',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.business, color: Color(0xFFE91E63)),
                                          enabled: false,
                                        ),
                                        child: Text(
                                          clients.firstWhere(
                                            (c) => c.id == _selectedClientId,
                                            orElse: () => clients.first,
                                          ).name,
                                          style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                        ),
                                      ),
                                    ] else ...[
                                      // Editable client dropdown
                                      DropdownButtonFormField<String>(
                                        value: _selectedClientId,
                                        decoration: InputDecoration(
                                          labelText: 'Client',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.business, color: Color(0xFFE91E63)),
                                        ),
                                        items: clients.map((client) {
                                          return DropdownMenuItem<String>(
                                            value: client.id,
                                            child: Text(
                                              client.name,
                                              style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) async {
                                          setState(() {
                                            _selectedClientId = value;
                                            _selectedProjectId = null;
                                          });
                                          if (value != null) {
                                            await projectProvider.setCurrentClient(value);
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a client';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 16),

                                    // Project Dropdown (disabled in edit mode)
                                    if (_isEditMode) ...[
                                      // Read-only project display
                                      InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Project',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.folder, color: Color(0xFFE91E63)),
                                          enabled: false,
                                        ),
                                        child: Text(
                                          projectProvider.getAllProjects().firstWhere(
                                            (p) => p.id == _selectedProjectId,
                                            orElse: () => projectProvider.getAllProjects().first,
                                          ).name,
                                          style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                        ),
                                      ),
                                    ] else ...[
                                      // Editable project dropdown
                                      DropdownButtonFormField<String>(
                                        value: _selectedProjectId,
                                        decoration: InputDecoration(
                                          labelText: 'Project',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.folder, color: Color(0xFFE91E63)),
                                        ),
                                        items: projects.map((project) {
                                          return DropdownMenuItem<String>(
                                            value: project.id,
                                            child: Text(
                                              project.name,
                                              style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _selectedClientId == null
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedProjectId = value;
                                                  if (value != null) {
                                                    final selectedProject =
                                                        projects.firstWhere(
                                                      (p) => p.id == value,
                                                    );
                                                    _contactNameController.text =
                                                        selectedProject.contactName ?? '';
                                                  } else {
                                                    _contactNameController.clear();
                                                  }
                                                });
                                              },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a project';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 16),

                                    // Contact Name
                                    TextFormField(
                                      controller: _contactNameController,
                                      style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                      decoration: InputDecoration(
                                        labelText: 'Site Contact Person',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: const Icon(Icons.person, color: Color(0xFFE91E63)),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter contact name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Date
                                    InkWell(
                                      onTap: () => _selectDate(context),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Date',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFE91E63)),
                                        ),
                                        child: Text(
                                          _formatDate(_selectedDate),
                                          style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                        ),
                                      ),
                                    ),

                                    // Status Dropdown (only in edit mode)
                                    if (_isEditMode) ...[
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: _selectedStatus,
                                        decoration: InputDecoration(
                                          labelText: 'Status',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.info_outline, color: Color(0xFFE91E63)),
                                        ),
                                        items: [
                                          DropdownMenuItem<String>(
                                            value: 'draft',
                                            child: Text(
                                              'Draft',
                                              style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                            ),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'done',
                                            child: Text(
                                              'Done',
                                              style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedStatus = value;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Audit Areas Section
                        Container(
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audit Areas',
                                  style: TextStyle(
                                    fontSize: Platform.isIOS ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _currentReportId != null
                                    ? Consumer3<AuditAreaEntryProvider,
                                        AuditAreaProvider, AuditIssueProvider>(
                                        builder: (context, entryProvider,
                                            auditAreaProvider, auditIssueProvider, _) {
                                          final entries = entryProvider
                                              .getEntriesForCurrentReport();

                                          if (entries.isEmpty) {
                                            return Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Text(
                                                  'No audit entries yet.\nTap + to add.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: Platform.isIOS ? 13 : 14,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: entries.length,
                                            itemBuilder: (context, index) {
                                              final entry = entries[index];

                                              final auditAreas = auditAreaProvider.getAllAuditAreas();
                                              final auditIssues = auditIssueProvider.getAllAuditIssues();

                                              final auditAreaName = auditAreas
                                                  .firstWhere((a) => a.id == entry.auditAreaId, orElse: () => auditAreas.first)
                                                  .name;

                                              // Get all audit issue names for the selected IDs
                                              final auditIssueNames = entry.auditIssueIds
                                                  .map((id) {
                                                    try {
                                                      return auditIssues.firstWhere((i) => i.id == id).name;
                                                    } catch (e) {
                                                      return null;
                                                    }
                                                  })
                                                  .where((name) => name != null)
                                                  .toList();

                                              final auditIssueName = auditIssueNames.isEmpty
                                                  ? 'No issues'
                                                  : auditIssueNames.join(', ');

                                              // All entries are automatically synced with Firestore
                                              const syncStatusIcon = Icon(Icons.cloud_done, color: Color(0xFF4CAF50), size: 20);

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey[200]!),
                                                ),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  leading: syncStatusIcon,
                                                  title: Text(
                                                    '$auditAreaName | $auditIssueName',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: Platform.isIOS ? 13 : 14,
                                                    ),
                                                  ),
                                                  subtitle: null, // Firestore handles syncing automatically
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3)),
                                                        onPressed: () => _editAuditEntry(entry),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                                                        onPressed: () => _deleteAuditEntry(entry.id),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Fill primary information first',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: Platform.isIOS ? 13 : 14,
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Consumer<BackgroundSyncService>(
                  builder: (context, syncService, _) {
                    final isSyncing = syncService.isSyncing;
                    final queueLength = syncService.queueLength;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                              child: Row(
                                children: [
                                // Save Button
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : _saveReport,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Color(0xFFE91E63)),
                                      foregroundColor: const Color(0xFFE91E63),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                                            ),
                                          )
                                        : Text(
                                            _isEditMode ? 'Update Report' : 'Save Report',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: Platform.isIOS ? 14 : 15,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Plus Button
                                FloatingActionButton(
                                  onPressed: _isAddingAuditArea ? null : _addAuditArea,
                                  backgroundColor: _isAddingAuditArea ? Colors.grey : const Color(0xFFE91E63),
                                  elevation: 4,
                                  child: _isAddingAuditArea
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.add, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                          ),
                        ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
