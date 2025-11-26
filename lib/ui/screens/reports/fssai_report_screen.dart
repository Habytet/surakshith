import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/constants/fssai_audit_points.dart';
import 'package:surakshith/data/providers/fssai_report_provider.dart';
import 'package:surakshith/data/providers/audit_area_entry_provider.dart';
import 'package:surakshith/data/providers/audit_issue_provider.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:surakshith/data/providers/report_provider.dart';
import 'package:surakshith/ui/screens/reports/fssai_pdf_screen.dart';
import 'package:intl/intl.dart';

class FssaiReportScreen extends StatefulWidget {
  final String clientId;
  final String projectId;
  final String reportId;

  const FssaiReportScreen({
    super.key,
    required this.clientId,
    required this.projectId,
    required this.reportId,
  });

  @override
  State<FssaiReportScreen> createState() => _FssaiReportScreenState();
}

class _FssaiReportScreenState extends State<FssaiReportScreen> {
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _fboController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _auditorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    final fssaiProvider = context.read<FssaiReportProvider>();
    await fssaiProvider.loadReport(widget.reportId);

    // Get data from various providers to auto-populate fields
    final clientProvider = context.read<ClientProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final reportProvider = context.read<ReportProvider>();
    final authProvider = context.read<AuthProvider>();

    // Get client (organization)
    final client = clientProvider.getAllClients()
        .where((c) => c.id == widget.clientId)
        .firstOrNull;

    // Get project (location)
    final project = projectProvider.getAllProjects()
        .where((p) => p.id == widget.projectId)
        .firstOrNull;

    // Get report (for contact name and date)
    final report = reportProvider.getAllReports()
        .where((r) => r.id == widget.reportId)
        .firstOrNull;

    // Get current user (auditor)
    final currentUser = authProvider.currentUser;

    // Auto-populate fields if not already saved
    if (fssaiProvider.currentReport != null) {
      // If data is already saved, use saved data; otherwise use auto-fetched data
      _organizationController.text = fssaiProvider.currentReport!.organizationName ?? client?.name ?? '';
      _fboController.text = fssaiProvider.currentReport!.fboName ?? report?.contactName ?? '';
      _locationController.text = fssaiProvider.currentReport!.location ?? project?.name ?? '';
      _auditorController.text = fssaiProvider.currentReport!.auditorName ?? currentUser?.email ?? '';
      _dateController.text = fssaiProvider.currentReport!.date ??
          (report != null ? DateFormat('dd/MM/yyyy').format(report.reportDate) : '');
    }
  }

  Future<void> _saveDetails() async {
    final provider = context.read<FssaiReportProvider>();
    await provider.updateReportDetails(
      organizationName: _organizationController.text.trim(),
      fboName: _fboController.text.trim(),
      location: _locationController.text.trim(),
      auditorName: _auditorController.text.trim(),
      date: _dateController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report details saved'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool _hasImagesForClause(int serialNo) {
    // Get all entries for this report
    final entryProvider = context.read<AuditAreaEntryProvider>();
    final issueProvider = context.read<AuditIssueProvider>();

    final entries = entryProvider.getAllEntries()
        .where((entry) => entry.reportId == widget.reportId)
        .toList();

    // Check if any images exist for this clause number
    for (final entry in entries) {
      for (final issueId in entry.auditIssueIds) {
        final issue = issueProvider.getAllAuditIssues()
            .where((i) => i.id == issueId)
            .firstOrNull;

        if (issue != null && issue.clauseNumbers.contains(serialNo)) {
          // Check if this entry has any images
          if (entry.imageUrls.isNotEmpty) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void _showImagesForClause(int serialNo) {
    // Get all entries for this report
    final entryProvider = context.read<AuditAreaEntryProvider>();
    final issueProvider = context.read<AuditIssueProvider>();

    final entries = entryProvider.getAllEntries()
        .where((entry) => entry.reportId == widget.reportId)
        .toList();

    // Collect images for this clause number
    final List<String> images = [];

    for (final entry in entries) {
      for (final issueId in entry.auditIssueIds) {
        final issue = issueProvider.getAllAuditIssues()
            .where((i) => i.id == issueId)
            .firstOrNull;

        if (issue != null && issue.clauseNumbers.contains(serialNo)) {
          // Add all images from this entry
          images.addAll(entry.imageUrls);
        }
      }
    }

    // If no images, silently return without showing any message
    if (images.isEmpty) {
      return;
    }

    // Show images in dialog
    showDialog(
      context: context,
      builder: (context) => _ImagesDialog(
        serialNo: serialNo,
        images: images,
      ),
    );
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
          'FSSAI Audit Report',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveDetails,
            icon: const Icon(Icons.save_outlined, size: 20),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FssaiPdfScreen(reportId: widget.reportId),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('Export'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
      body: Consumer<FssaiReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Details Section - Collapsible
              Container(
                color: Colors.white,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: Platform.isIOS ? 17 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _organizationController,
                            label: 'Organization Name',
                            icon: Icons.business,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _fboController,
                            label: 'FBO Name',
                            icon: Icons.restaurant,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _auditorController,
                            label: 'Auditor Name',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _dateController,
                            label: 'Date',
                            icon: Icons.calendar_today,
                            readOnly: true,
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Score Summary Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Score',
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${provider.totalScore} / ${provider.totalMaxScore}',
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 24 : 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audit Points List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: FssaiAuditPoints.allPoints.length,
                  itemBuilder: (context, index) {
                    final point = FssaiAuditPoints.allPoints[index];
                    final score = provider.getScore(point.serialNo);
                    final hasImages = _hasImagesForClause(point.serialNo);

                    return _buildAuditPointCard(
                      point: point,
                      score: score,
                      hasImages: hasImages,
                      onScoreChanged: (newScore) {
                        provider.updateScore(point.serialNo, newScore);
                      },
                      onTap: hasImages ? () => _showImagesForClause(point.serialNo) : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildAuditPointCard({
    required FssaiAuditPoint point,
    required int score,
    required bool hasImages,
    required ValueChanged<int> onScoreChanged,
    required VoidCallback? onTap,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Serial Number Badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${point.serialNo}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Max Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Max: ${point.maxScore}',
                        style: TextStyle(
                          fontSize: Platform.isIOS ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Score Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: score == point.maxScore
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: score == point.maxScore
                              ? const Color(0xFF10B981)
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<int>(
                        value: score,
                        underline: const SizedBox(),
                        isDense: true,
                        items: List.generate(
                          point.maxScore + 1,
                          (index) => DropdownMenuItem(
                            value: index,
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontSize: Platform.isIOS ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: index == point.maxScore
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            onScoreChanged(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  point.description,
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 13 : 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Image status hint
                Row(
                  children: [
                    Icon(
                      hasImages ? Icons.image_outlined : Icons.hide_image_outlined,
                      size: 14,
                      color: hasImages ? const Color(0xFF10B981) : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasImages ? 'Tap to view mapped images' : 'No images mapped',
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 11 : 12,
                        color: hasImages ? const Color(0xFF10B981) : Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _fboController.dispose();
    _locationController.dispose();
    _auditorController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}

class _ImagesDialog extends StatelessWidget {
  final int serialNo;
  final List<String> images;

  const _ImagesDialog({
    required this.serialNo,
    required this.images,
  });

  void _showFullScreenImage(BuildContext context, String imagePath) {
    final isNetworkImage = imagePath.startsWith('http');

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen interactive image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.error_outline, size: 60, color: Colors.white),
                          ),
                        ),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.error_outline, size: 60, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: Material(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$serialNo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mapped Images',
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 17 : 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Images Grid
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  final isNetworkImage = imagePath.startsWith('http');

                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, imagePath),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isNetworkImage
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error_outline, size: 40),
                              ),
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error_outline, size: 40),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            // Count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${images.length} image${images.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 13 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
