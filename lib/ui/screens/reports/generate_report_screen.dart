import 'dart:io';
import 'package:flutter/material.dart';
import 'package:surakshith/ui/screens/reports/custom_report_pdf_screen.dart';
import 'package:surakshith/ui/screens/reports/fssai_report_screen.dart';

class GenerateReportScreen extends StatelessWidget {
  final String clientId;
  final String projectId;
  final String reportId;

  const GenerateReportScreen({
    super.key,
    required this.clientId,
    required this.projectId,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: Text(
          'Generate Report',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Report Format',
              style: TextStyle(
                fontSize: Platform.isIOS ? 22 : 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the format you want to generate your report in',
              style: TextStyle(
                fontSize: Platform.isIOS ? 14 : 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Custom Report Card
            _buildReportCard(
              context: context,
              title: 'Custom Report',
              description: 'Generate a customized report with your preferred layout and content',
              icon: Icons.tune,
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CustomReportPdfScreen(
                      clientId: clientId,
                      projectId: projectId,
                      reportId: reportId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // FSSAI Report Card
            _buildReportCard(
              context: context,
              title: 'FSSAI Audit Report',
              description: 'Generate FSSAI compliance audit report with 51 checkpoint assessment',
              icon: Icons.verified_user,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FssaiReportScreen(
                      clientId: clientId,
                      projectId: projectId,
                      reportId: reportId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 17 : 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: Platform.isIOS ? 13 : 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
