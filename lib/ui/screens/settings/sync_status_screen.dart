import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/audit_area_entry_provider.dart';
import '../../../data/providers/report_provider.dart';
import '../../../data/providers/audit_area_provider.dart';
import '../../../data/models/audit_area_entry_model.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final entryProvider = context.watch<AuditAreaEntryProvider>();
    final reportProvider = context.read<ReportProvider>();
    final auditAreaProvider = context.read<AuditAreaProvider>();

    // Get all entries (all are backed up with Firestore)
    final allEntries = entryProvider.getAllEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Status'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_done,
                          color: Color(0xFF4CAF50),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All Backed Up',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your data is automatically synced to the cloud',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    count: allEntries.length,
                    label: 'Total Entries',
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.cloud_done,
                    count: allEntries.length,
                    label: 'Backed Up',
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recently Synced Section
            if (allEntries.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Entries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  if (allEntries.length > 5)
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('All Backed Up Items'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 400,
                              child: ListView(
                                children: allEntries.map((entry) => _buildEntryCard(
                                  entry: entry,
                                  reportProvider: reportProvider,
                                  auditAreaProvider: auditAreaProvider,
                                )).toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: Text('View All (${allEntries.length})'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...allEntries.take(5).map((entry) => _buildEntryCard(
                entry: entry,
                reportProvider: reportProvider,
                auditAreaProvider: auditAreaProvider,
              )),
            ],

            if (allEntries.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create audit entries to see backup status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard({
    required AuditAreaEntryModel entry,
    required ReportProvider reportProvider,
    required AuditAreaProvider auditAreaProvider,
  }) {
    // Get report name (use formatted date since ReportModel doesn't have a name field)
    String reportName = 'Unknown Report';
    try {
      final report = reportProvider.getAllReports()
        .firstWhere((r) => r.id == entry.reportId);
      reportName = 'Report ${DateFormat('dd MMM yyyy').format(report.reportDate)}';
    } catch (e) {
      // Keep default
    }

    // Get audit area name
    String auditAreaName = 'Unknown Area';
    try {
      final auditArea = auditAreaProvider.getAllAuditAreas()
        .firstWhere((a) => a.id == entry.auditAreaId);
      auditAreaName = auditArea.name;
    } catch (e) {
      // Keep default
    }

    // Format timestamp
    String timeStr = 'Just now';
    final timestamp = entry.createdAt;

    if (timestamp != null) {
      final now = DateTime.now();
      final diff = now.difference(timestamp);

      if (diff.inMinutes < 1) {
        timeStr = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours}h ago';
      } else {
        timeStr = DateFormat('dd MMM').format(timestamp);
      }
    }

    const statusIcon = Icons.check_circle;
    const statusColor = Color(0xFF4CAF50);
    const statusText = 'Backed up';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(statusIcon, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auditAreaName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reportName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (entry.imageUrls.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.imageUrls.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
