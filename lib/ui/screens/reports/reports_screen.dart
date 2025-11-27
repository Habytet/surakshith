import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:surakshith/data/providers/report_provider.dart';
import 'package:surakshith/ui/screens/reports/report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedClientId;
  String? _selectedProjectId;
  bool _showFilters = false;
  String _sortOrder = 'newest'; // 'newest' or 'oldest'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sync all reports from Firebase in background (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAllReportsFromFirebase();
    });
  }

  void _syncAllReportsFromFirebase() {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    final allProjects = projectProvider.getAllProjects();

    print('🔵 [REPORTS_SCREEN] Starting Firebase sync...');
    print('🔵 [REPORTS_SCREEN] Found ${allProjects.length} projects');

    if (allProjects.isNotEmpty) {
      // Create projectId -> clientId mapping
      final projectClientMap = <String, String>{};
      for (var project in allProjects) {
        projectClientMap[project.id] = project.clientId;
        print('🔵 [REPORTS_SCREEN] Project: ${project.name} (ID: ${project.id}, ClientID: ${project.clientId})');
      }

      print('🔵 [REPORTS_SCREEN] No manual sync needed - Firestore handles this automatically');
      // Real-time sync is handled by Firestore listeners
      // reportProvider.syncAllReports(projectClientMap); // NO LONGER NEEDED
    } else {
      print('🔴 [REPORTS_SCREEN] No projects found - cannot sync reports');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Search
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search reports...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                          color: const Color(0xFFE91E63),
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF222222),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Platform.isIOS ? 14 : 15,
                  ),
                  indicatorColor: const Color(0xFFE91E63),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Drafts'),
                    Tab(text: 'Done'),
                  ],
                ),
              ],
            ),
          ),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList('all'),
                _buildReportsList('draft'),
                _buildReportsList('done'),
              ],
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ReportFormScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFE91E63),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer2<ClientProvider, ProjectProvider>(
      builder: (context, clientProvider, projectProvider, child) {
        final clients = clientProvider.getAllClients();
        final projects = _selectedClientId != null
            ? projectProvider.getAllProjects().where((p) => p.clientId == _selectedClientId).toList()
            : [];

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Sort Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _sortOrder,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: InputBorder.none,
                    icon: Icon(Icons.sort, color: Color(0xFFE91E63)),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'newest',
                      child: Text('Date (Newest First)'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'oldest',
                      child: Text('Date (Oldest First)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOrder = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Client Filter
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Client',
                    border: InputBorder.none,
                    icon: Icon(Icons.business_outlined, color: Color(0xFF3F51B5)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Clients'),
                    ),
                    ...clients.map((client) {
                      return DropdownMenuItem<String>(
                        value: client.id,
                        child: Text(client.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                      _selectedProjectId = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Project Filter
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Project',
                    border: InputBorder.none,
                    icon: Icon(Icons.folder_outlined, color: Color(0xFF9C27B0)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Projects'),
                    ),
                    ...projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Date Filter
              InkWell(
                onTap: _showDateRangePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_outlined, color: Color(0xFFFF9800)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _getDateRangeText(),
                          style: TextStyle(fontSize: Platform.isIOS ? 14 : 15),
                        ),
                      ),
                      if (_fromDate != null || _toDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearDateFilter,
                        )
                      else
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsList(String status) {
    return Consumer3<ReportProvider, ClientProvider, ProjectProvider>(
      builder: (context, reportProvider, clientProvider, projectProvider, _) {
        if (!reportProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE91E63),
            ),
          );
        }

        // Get all reports
        var reports = reportProvider.getAllReports();
        print('📊 [REPORTS_LIST] Total reports in local storage: ${reports.length} (status filter: $status)');

        // Filter by status
        if (status == 'draft') {
          reports = reports.where((r) => r.status == 'draft').toList();
        } else if (status == 'done') {
          reports = reports.where((r) => r.status == 'done').toList();
        }

        // Apply filters
        if (_selectedClientId != null) {
          reports = reports.where((r) => r.clientId == _selectedClientId).toList();
        }
        if (_selectedProjectId != null) {
          reports = reports.where((r) => r.projectId == _selectedProjectId).toList();
        }
        if (_fromDate != null) {
          reports = reports
              .where((r) => r.reportDate.isAfter(_fromDate!) || r.reportDate.isAtSameMomentAs(_fromDate!))
              .toList();
        }
        if (_toDate != null) {
          final endDate = _toDate!.add(const Duration(days: 1));
          reports = reports
              .where((r) => r.reportDate.isBefore(endDate) || r.reportDate.isAtSameMomentAs(endDate))
              .toList();
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          final allClients = clientProvider.getAllClients();
          final allProjects = projectProvider.getAllProjects();
          reports = reports.where((r) {
            final clientIndex = allClients.indexWhere((c) => c.id == r.clientId);
            final projectIndex = allProjects.indexWhere((p) => p.id == r.projectId);

            // Skip if client or project not found
            if (clientIndex == -1 || projectIndex == -1) return false;

            final client = allClients[clientIndex];
            final project = allProjects[projectIndex];

            return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                project.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              _syncAllReportsFromFirebase();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFFE91E63),
            child: _buildEmptyState(status),
          );
        }

        // Sort by date based on user selection
        if (_sortOrder == 'newest') {
          // Newest first - sort by report date descending
          reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
        } else {
          // Oldest first - sort by report date ascending
          reports.sort((a, b) => a.reportDate.compareTo(b.reportDate));
        }

        final allClients = clientProvider.getAllClients();
        final allProjects = projectProvider.getAllProjects();

        return RefreshIndicator(
          onRefresh: () async {
            _syncAllReportsFromFirebase();
            // Give it a moment to fetch from Firebase
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
            final report = reports[index];

            // Find client and project - skip if not found
            final clientIndex = allClients.indexWhere((c) => c.id == report.clientId);
            final projectIndex = allProjects.indexWhere((p) => p.id == report.projectId);

            // Skip this report if client or project data not available
            if (clientIndex == -1 || projectIndex == -1) {
              return const SizedBox.shrink();
            }

            final client = allClients[clientIndex];
            final project = allProjects[projectIndex];
            final reportDate = report.reportDate;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReportFormScreen(report: report),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: report.status == 'done'
                          ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                          : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    report.status == 'done'
                        ? Icons.check_circle_outline
                        : Icons.edit_note_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  client.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Platform.isIOS ? 14 : 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.name,
                            style: TextStyle(fontSize: Platform.isIOS ? 12 : 13, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(reportDate),
                          style: TextStyle(fontSize: Platform.isIOS ? 11 : 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ),
            );
          },
        ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String title;
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty ||
        _fromDate != null ||
        _toDate != null ||
        _selectedClientId != null ||
        _selectedProjectId != null) {
      title = 'No reports found';
      message = 'Try adjusting your filters';
      icon = Icons.search_off_outlined;
    } else {
      switch (status) {
        case 'draft':
          title = 'No draft reports';
          message = 'Draft reports will appear here';
          icon = Icons.edit_note_outlined;
          break;
        case 'done':
          title = 'No completed reports';
          message = 'Completed reports will appear here';
          icon = Icons.check_circle_outline;
          break;
        default:
          title = 'No reports yet';
          message = 'Tap + to create your first report';
          icon = Icons.description_outlined;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 13 : 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDateRangeText() {
    if (_fromDate == null && _toDate == null) {
      return 'Filter by date range';
    } else if (_fromDate != null && _toDate != null) {
      return '${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)}';
    } else if (_fromDate != null) {
      return 'From ${_formatDate(_fromDate!)}';
    } else if (_toDate != null) {
      return 'Until ${_formatDate(_toDate!)}';
    }
    return 'Filter by date range';
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
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
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }
}
